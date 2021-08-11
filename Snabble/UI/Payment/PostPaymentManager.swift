//
//  PostPaymentManager.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

extension Notification.Name {
    public static let snabbleFulfillmentsDone = Notification.Name("snabbleFulfillmentsDone")
    public static let snabbleFulfillmentsUpdate = Notification.Name("snabbleFulfillmentsUpdate")
}

protocol PostPaymentManagerDelegate: AnyObject {
    func postPaymentManager(
        _ manager: PostPaymentManager,
        didUpdateCheckoutProcess checkoutProcess: CheckoutProcess,
        withRawJson rawJson: [String: Any]?,
        forProject project: Project
    )

    func postPaymentManager(
        _ manager: PostPaymentManager,
        didCompleteCheckoutProcess checkoutProcess: CheckoutProcess,
        withRawJson rawJson: [String: Any]?,
        forProject project: Project
    )

    func shouldRetryFailedUpdate(
        on manager: PostPaymentManager,
        withCheckoutProcess checkoutProcess: CheckoutProcess,
        forProject project: Project
    ) -> Bool
}

final class PostPaymentManager {
    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?

    weak var delegate: PostPaymentManagerDelegate?

    let project: Project
    let checkoutProcess: CheckoutProcess

    init(project: Project, checkoutProcess: CheckoutProcess) {
        self.project = project
        self.checkoutProcess = checkoutProcess
    }

    deinit {
        stop()
    }

    func start() {
        processTimer?.invalidate()
        processTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: false
        ) { [unowned self] timer in
            guard timer.isValid else { return }
            checkoutProcess.update(
                project,
                taskCreated: {
                    sessionTask = $0
                },
                completion: {
                    update(result: $0)
                })
        }
    }

    func stop() {
        processTimer?.invalidate()
        sessionTask?.cancel()
        sessionTask = nil
    }

    // MARK: - process updates
    private func update(result: RawResult<CheckoutProcess, SnabbleError>) {
        switch result.result {
        case .success(let process):
            validateProcess(
                for: process,
                withRawJson: result.rawJson
            )
            postNotification(
                for: process,
                withRawJson: result.rawJson
            )
        case .failure(let error):
            Log.error(String(describing: error))
            let shouldRetry = delegate?.shouldRetryFailedUpdate(
                on: self,
                withCheckoutProcess: checkoutProcess,
                forProject: project
            )
            if shouldRetry ?? true {
                start()
            }
        }
    }

    private func validateProcess(for process: CheckoutProcess, withRawJson rawJson: [String: Any]?) {
        let isCompleted: Bool
        if process.requiresExitToken {
            isCompleted = process.fulfillmentsDone() && process.exitToken?.value != nil
        } else {
            isCompleted = process.fulfillmentsDone()
        }

        if isCompleted {
            delegate?.postPaymentManager(
                self,
                didCompleteCheckoutProcess: process,
                withRawJson: rawJson,
                forProject: project
            )
            stop()
        } else {
            delegate?.postPaymentManager(
                self,
                didUpdateCheckoutProcess: process,
                withRawJson: rawJson,
                forProject: project
            )
            start()
        }
    }

    private func postNotification(for process: CheckoutProcess, withRawJson rawJson: [String: Any]?) {
        let fulfillments = process.fulfillments
        let count = fulfillments.count

        let states = fulfillments.map { $0.state }
        let finished = states.filter { FulfillmentState.endStates.contains($0) }.count
        let succeeded = states.filter { $0 == .processed }.count
        let failed = states.filter { FulfillmentState.failureStates.contains($0) }.count

        let userInfo: [AnyHashable: Any] = [
            "checkoutProcess": process,
            "checkoutProcessJson": rawJson ?? [:],
            "successCount": succeeded,
            "failedCount": failed
        ]

        NotificationCenter.default.post(
            name: finished == count ? .snabbleFulfillmentsDone : .snabbleFulfillmentsUpdate,
            object: self,
            userInfo: userInfo
        )
    }
}
