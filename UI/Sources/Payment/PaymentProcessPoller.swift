//
//  PaymentProcessPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

public enum PaymentEvent: Sendable {
    case paymentSuccess

    case receipt
}

public final class PaymentProcessPoller: @unchecked Sendable {
    private weak var timer: Timer?

    private let process: CheckoutProcess
    private let project: Project

    private var task: URLSessionDataTask?
    private var completion: ((Bool) -> Void)?

    private var waitingFor = [PaymentEvent]()
    private var alreadySeen = [PaymentEvent]()

    private(set) var updatedProcess: CheckoutProcess

    private(set) var failureCause: FailureCause?

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

        self.task?.cancel()
        self.task = nil

        self.completion = nil
    }

    // wait for a number of events, and call the completion handler as soon as one (or more) are fulfilled
    public func waitFor(_ events: [PaymentEvent], completion: @escaping @Sendable ([PaymentEvent: Bool]) -> Void ) {
        self.waitingFor = events
        self.alreadySeen = []
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkEvents(completion)
        }
    }

    private func checkEvents(_ completion: @escaping @Sendable ([PaymentEvent: Bool]) -> Void ) {
        self.process.update(self.project, taskCreated: { self.task = $0 }, completion: { result in
            switch result.result {
            case .failure(let error):
                if case .httpError = error {
                    self.timer?.invalidate()
                }
            case .success(let process):
                self.updatedProcess = process
                self.checkProcess(process, completion)
            }
        })
    }

    private func checkProcess(_ process: CheckoutProcess, _ completion: @escaping @Sendable ([PaymentEvent: Bool]) -> Void ) {
        if let failureCause = process.paymentResult?["failureCause"] as? String {
            self.failureCause = FailureCause(rawValue: failureCause)
        }

        var seenNow = [PaymentEvent: Bool]()
        var abort = false
        for event in self.waitingFor {
            if self.alreadySeen.contains(event) {
                continue
            }

            var result: (event: PaymentEvent, ok: Bool)?
            switch event {
            case .paymentSuccess: result = self.checkPayment(process)
            case .receipt: result = self.checkReceipt(process)
            }

            if let result = result {
                seenNow[result.event] = result.ok
                self.alreadySeen.append(result.event)
                abort = abort || !result.ok
            }
        }

        if !seenNow.isEmpty {
            completion(seenNow)
        }

        if abort || self.alreadySeen.count == self.waitingFor.count {
            self.timer?.invalidate()
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
        if process.links.receipt != nil {
            return (.receipt, true)
        }

        let paymentFinished = PaymentState.endStates.contains(process.paymentState)
        if paymentFinished && process.fulfillmentsDone() {
            return (.receipt, false)
        }

        return nil
    }

}
