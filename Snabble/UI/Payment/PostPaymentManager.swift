//
//  FulfillmentPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
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
        includesExitToken hasExitToken: Bool,
        forProject project: Project
    )

    func postPaymentManager(
        _ manager: PostPaymentManager,
        didCompleteCheckoutProcess checkoutProcess: CheckoutProcess,
        withRawJson rawJson: [String: Any]?,
        includesExitToken hasExitToken: Bool,
        forProject project: Project
    )
}

final class PostPaymentManager {

    private var processTimer: Timer?
    private var sessionTask: URLSessionTask?

    weak var delegate: PostPaymentManagerDelegate?

    let project: Project
    let checkoutProcess: CheckoutProcess

    init(project: Project, checkoutProcess: CheckoutProcess) {
        self.project = project
        self.checkoutProcess = checkoutProcess
    }

    deinit {
        cancel()
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

    private func cancel() {
        processTimer?.invalidate()
        processTimer = nil

        sessionTask?.cancel()
        sessionTask = nil
    }

    // MARK: - process updates
    private func update(
        result: RawResult<CheckoutProcess, SnabbleError>
    ) {
        switch result.result {
        case .success(let process):
            validateProcess(
                for: process,
                with: result.rawJson
            )
            notifications(
                for: process,
                withRawJson: result.rawJson
            )
        case .failure(let error):
            start()
            Log.error(String(describing: error))
        }
    }

    private func validateProcess(
        for process: CheckoutProcess,
        with rawJson: [String: Any]?
    ) {
        // Delegation
        let requiresExitToken = process.exitToken != nil

        let isCompleted: Bool
        if requiresExitToken {
            isCompleted = process.fulfillmentsDone() && process.exitToken?.value != nil
        } else {
            isCompleted = process.fulfillmentsDone()
        }

        if isCompleted {
            delegate?.postPaymentManager(
                self,
                didCompleteCheckoutProcess: process,
                withRawJson: rawJson,
                includesExitToken: requiresExitToken,
                forProject: project
            )
            cancel()
        } else {
            delegate?.postPaymentManager(
                self,
                didUpdateCheckoutProcess: process,
                withRawJson: rawJson,
                includesExitToken: requiresExitToken,
                forProject: project
            )
            start()
        }
    }

    private func notifications(for process: CheckoutProcess, withRawJson rawJson: [String: Any]?) {
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

        let name: NSNotification.Name = finished == count ? .snabbleFulfillmentsDone : .snabbleFulfillmentsUpdate
        NotificationCenter.default.post(
            name: name,
            object: self,
            userInfo: userInfo
        )
    }
}
