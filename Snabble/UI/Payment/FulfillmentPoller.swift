//
//  FulfillmentPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

extension Notification.Name {
    public static let snabbleFulfillmentsDone = Notification.Name("snabbleFulfillmentsDone")
    public static let snabbleFulfillmentsUpdate = Notification.Name("snabbleFulfillmentsUpdate")
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

        let userInfo: [AnyHashable: Any] = [
            "checkoutProcess": process,
            "checkoutProcessJson": rawJson ?? [:],
            "successCount": succeeded,
            "failedCount": failed
        ]

        if ended == count {
            Log.debug("fulfillment poller done, success=\(succeeded) failed=\(failed)")
            NotificationCenter.default.post(name: .snabbleFulfillmentsDone, object: self, userInfo: userInfo)
            return false
        } else {
            Log.debug("fulfillment poller: waiting for \(count), ended so far=\(ended)")
            NotificationCenter.default.post(name: .snabbleFulfillmentsUpdate, object: self, userInfo: userInfo)
        }

        return true
    }
}
