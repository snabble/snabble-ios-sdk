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

    public init(_ process: CheckoutProcess, _ project: Project) {
        self.process = process
        self.updatedProcess = process
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
            guard case Result.success(let process) = result else {
                return
            }

            if let candidateLink = process.paymentResult?["originCandidateLink"] as? String {
                OriginPoller.shared.startPolling(self.project, candidateLink)
            }

            self.updatedProcess = process

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

class OriginPoller {
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
                    self.stopPolling()
                }
            }
        }
    }
}
