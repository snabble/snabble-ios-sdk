//
//  PaymentProcessPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public enum PaymentEvent {
    case approval
    case paymentSuccess

    case receipt

    var abortOnFailure: Bool {
        switch self {
        case .approval: return true
        case .paymentSuccess: return true
        case .receipt: return false
        }
    }
}

public final class PaymentProcessPoller {
    private var timer: Timer?

    private let process: CheckoutProcess
    private let project: Project

    private var task: URLSessionDataTask?
    private var completion: ((Bool) -> Void)?

    private var waitingFor = [PaymentEvent]()
    private var alreadySeen = [PaymentEvent]()

    private(set) var updatedProcess: CheckoutProcess
    private(set) var rawJson: [String: Any]?

    public init(_ process: CheckoutProcess, _ rawJson: [String: Any]?, _ project: Project) {
        self.process = process
        self.updatedProcess = process
        self.rawJson = rawJson
        self.project = project
    }

    deinit {
        self.stop()
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil

        self.task?.cancel()
        self.task = nil

        self.completion = nil
    }

    // wait for a number of events, and call the completion handler as soon as one (or more) are fulfilled
    public func waitFor(_ events: [PaymentEvent], completion: @escaping ([PaymentEvent: Bool]) -> Void ) {
        self.waitingFor = events
        self.alreadySeen = []
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkEvents(events, completion)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func checkEvents(_ events: [PaymentEvent], _ completion: @escaping ([PaymentEvent: Bool]) -> Void ) {
        self.process.update(self.project, taskCreated: { self.task = $0 }, completion: { result in
            guard case Result.success(let process) = result.result else {
                return
            }

            if let candidateLink = process.paymentResult?["originCandidateLink"] as? String {
                OriginPoller.shared.startPolling(self.project, candidateLink)
            }

            self.updatedProcess = process
            self.rawJson = result.rawJson

            var seenNow = [PaymentEvent: Bool]()
            var abort = false
            for event in self.waitingFor {
                if self.alreadySeen.contains(event) {
                    continue
                }

                var result: (event: PaymentEvent, ok: Bool)?
                switch event {
                case .approval: result = self.checkApproval(process)
                case .paymentSuccess: result = self.checkPayment(process)
                case .receipt: result = self.checkReceipt(process)
                }

                if let result = result {
                    seenNow[result.event] = result.ok
                    self.alreadySeen.append(result.event)
                    if result.event.abortOnFailure {
                        abort = abort || !result.ok
                    }
                }
            }

            if !seenNow.isEmpty {
                completion(seenNow)
            }

            if abort || self.alreadySeen.count == self.waitingFor.count {
                self.timer?.invalidate()
                self.timer = nil
            }
        })
    }

    private func checkApproval(_ process: CheckoutProcess) -> (PaymentEvent, Bool)? {
        // print("approval: \(process.paymentApproval) \(process.supervisorApproval)")
        switch (process.paymentApproval, process.supervisorApproval) {
        case (.none, .none):
            return nil
        case (.some(let paymentApproval), .none):
            return paymentApproval ? nil : (.approval, false)
        case (.none, .some(let supervisorApproval)):
            return supervisorApproval ? nil : (.approval, false)
        case (.some(let paymentApproval), .some(let supervisorApproval)):
            return (.approval, paymentApproval && supervisorApproval)
        }
    }

    private func checkPayment(_ process: CheckoutProcess) -> (PaymentEvent, Bool)? {
        // print("paymentState: \(process.paymentState)")
        let skipStates = [PaymentState.pending, .processing ]
        if skipStates.contains(process.paymentState) {
            return nil
        }

        return (.paymentSuccess, process.paymentState == .successful)
    }

    private func checkReceipt(_ process: CheckoutProcess) -> (PaymentEvent, Bool)? {
        guard process.links.receipt != nil else {
            return nil
        }

        return (.receipt, true)
    }

}

extension Notification.Name {
    public static let snabbleOriginCandidateReceived = Notification.Name("snabbleOriginCandidateReceived")
}

final class OriginPoller {
    static let shared = OriginPoller()

    private var project: Project?
    private var timer: Timer?
    private var candidates = Set<String>()

    private init() {}

    func startPolling(_ project: Project, _ url: String) {
        if self.project == nil && !self.candidates.contains(url) {
            self.project = project

            self.checkCandidate(url)
        }
    }

    private func stopPolling() {
        self.timer?.invalidate()
        self.timer = nil
        self.project = nil
    }

    private func checkCandidate(_ url: String) {
        self.project?.request(.get, url, timeout: 2) { request in
            guard let request = request else {
                return self.stopPolling()
            }

            self.project?.perform(request) { (result: Result<OriginCandidate, SnabbleError>, response) in
                if response?.statusCode == 404 {
                    return self.stopPolling()
                }

                var continuePolling = true
                switch result {
                case .failure(let error):
                    Log.error("error getting originCandidate: \(error)")
                case .success(let candidate):
                    let valid = candidate.isValid
                    if valid {
                        self.candidates.insert(url)
                        let nc = NotificationCenter.default
                        nc.post(name: .snabbleOriginCandidateReceived, object: nil, userInfo: [ "candidate": candidate ])
                    }
                    continuePolling = !valid
                }

                if continuePolling {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.checkCandidate(url)
                    }
                } else {
                    self.candidates.remove(url)
                    self.stopPolling()
                }
            }
        }
    }
}

extension Notification.Name {
    public static let snabbleFulfillmentsDone = Notification.Name("snabbleFulfillmentsDone")
}

final class FulfillmentPoller {
    static let shared = FulfillmentPoller()

    private var processTimer: Timer?
    private var sessionTask: URLSessionTask?
    private var project: Project?
    private var process: CheckoutProcess?

    private init() {}

    func startPolling(_ project: Project, _ process: CheckoutProcess) {
        if self.process == nil && self.process == nil {
            self.project = project
            self.process = process

            self.startTimer()
        }
    }

    // MARK: - polling timer
    private func startTimer() {
        guard
            let process = self.process,
            let project = self.project
        else {
            return
        }

        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            process.update(project,
                           taskCreated: { self.sessionTask = $0 },
                           completion: { self.update($0) })
        }
    }

    private func stopPolling() {
        self.processTimer?.invalidate()
        self.processTimer = nil

        self.sessionTask?.cancel()
        self.sessionTask = nil

        self.project = nil
        self.process = nil
    }

    // MARK: - process updates
    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        var continuePolling = true
        switch result.result {
        case .success(let process):
            continuePolling = self.checkFulfillmentStatus(process, result.rawJson)
        case .failure(let error):
            Log.error(String(describing: error))
        }

        if continuePolling {
            self.startTimer()
        } else {
            self.stopPolling()
        }
    }

    func checkFulfillmentStatus(_ process: CheckoutProcess, _ rawJson: [String: Any]?) -> Bool {
        let fulfillments = process.fulfillments
        let count = fulfillments.count

        let states = fulfillments.map { $0.state }
        let ended = states.filter { FulfillmentState.endStates.contains($0) }.count
        let succeeded = states.filter { $0 == .processed }.count
        let failed = states.filter { FulfillmentState.failureStates.contains($0) }.count

        if ended == count {
            let userInfo: [AnyHashable: Any] = [
                "checkoutProcess": process,
                "checkoutProcessJson": rawJson ?? [:],
                "successCount": succeeded,
                "failedCount": failed
            ]
            Log.debug("fulfillment poller done, success=\(succeeded) failed=\(failed)")
            NotificationCenter.default.post(name: .snabbleFulfillmentsDone, object: self, userInfo: userInfo)
            return false
        } else {
            Log.debug("fulfillment poller: waiting for \(count), ended so far=\(ended)")
        }

        return true
    }
}
