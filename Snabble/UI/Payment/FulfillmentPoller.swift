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
    public typealias Handler = (_ fulfillments: [Fulfillment]) -> Void

    private var processTimer: Timer?
    private var sessionTask: URLSessionTask?

    let project: Project
    let process: CheckoutProcess

    init(project: Project, process: CheckoutProcess) {
        self.project = project
        self.process = process
    }

    deinit {
        cancel()
    }

    func start(
        progressHandler: @escaping Handler,
        completionHandler: @escaping Handler
    ) {
        processTimer?.invalidate()
        processTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: false
        ) { [unowned self] _ in
            process.update(
                project,
                taskCreated: {
                    sessionTask = $0
                },
                completion: {
                    update(
                        result: $0,
                        progressHandler: progressHandler,
                        completionHandler: completionHandler
                    )
                })
        }
    }

    private func cancel() {
        processTimer?.invalidate()
        processTimer = nil

        sessionTask?.cancel()
        sessionTask = nil
    }

    // MARK: - process updates
    private func update(
        result: RawResult<CheckoutProcess, SnabbleError>,
        progressHandler: @escaping Handler,
        completionHandler: @escaping Handler
    ) {
        let continuePolling: Bool
        switch result.result {
        case .success(let process):
            continuePolling = checkFulfillmentStatus(
                for: process,
                with: result.rawJson,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
        case .failure(let error):
            continuePolling = true
            Log.error(String(describing: error))
        }

        if continuePolling {
            start(progressHandler: progressHandler, completionHandler: completionHandler)
            progressHandler(process.fulfillments)
        } else {
            cancel()
            completionHandler(process.fulfillments)
        }
    }

    private func checkFulfillmentStatus(
        for process: CheckoutProcess,
        with rawJson: [String: Any]?,
        progressHandler: @escaping Handler,
        completionHandler: @escaping Handler
    ) -> Bool {
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
            return true
        }
    }
}
