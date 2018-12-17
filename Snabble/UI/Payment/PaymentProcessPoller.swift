//
//  PaymentProcessPoller.swift
//  Snabble
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

enum PaymentEvent {
    case approval
    case paymentSuccess

    var abortOnFailure: Bool {
        switch self {
        case .approval: return true
        case .paymentSuccess: return true
        }
    }
}

final class PaymentProcessPoller {
    private var timer: Timer?

    private let process: CheckoutProcess
    private let project: Project
    private let shop: Shop

    private var task: URLSessionDataTask?
    private var completion: ((Bool) -> ())?

    private var waitingFor = [PaymentEvent]()
    private var alreadySeen = [PaymentEvent]()

    init(_ process: CheckoutProcess, _ project: Project, _ shop: Shop) {
        self.process = process
        self.project = project
        self.shop = shop
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
    func waitFor(_ events: [PaymentEvent], completion: @escaping ([PaymentEvent: Bool]) -> () ) {
        self.waitingFor = events
        self.alreadySeen = []
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkEvents(events, completion)
        }
    }

    private func checkEvents(_ events: [PaymentEvent], _ completion: @escaping ([PaymentEvent: Bool]) -> () ) {
        self.process.update(self.project, taskCreated: { self.task = $0 }) { result in
            guard case Result.success(let process) = result else {
                return
            }

            var seenNow = [PaymentEvent: Bool]()
            var abort = false
            for event in self.waitingFor {
                if self.alreadySeen.contains(event) {
                    continue
                }

                var result: (event: PaymentEvent, ok: Bool)? = nil
                switch event {
                case .approval: result = self.checkApproval(process)
                case .paymentSuccess: result = self.checkPayment(process)
                }

                if let result = result {
                    seenNow[result.event] = result.ok
                    self.alreadySeen.append(result.event)
                    if result.event.abortOnFailure {
                        abort = abort || !result.ok
                    }
                }
            }

            if seenNow.count > 0 {
                completion(seenNow)
            }

            if abort || self.alreadySeen.count == self.waitingFor.count {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }

    private func checkApproval(_ process: CheckoutProcess) -> (PaymentEvent, Bool)? {
        guard
            let paymentApproval = process.paymentApproval,
            let supervisorApproval = process.supervisorApproval
        else {
            return nil
        }

        return (.approval, paymentApproval && supervisorApproval)
    }

    private func checkPayment(_ process: CheckoutProcess) -> (PaymentEvent, Bool)? {
        guard process.paymentState != .pending else {
            return nil
        }

        return (.paymentSuccess, process.paymentState == .successful)
    }

}
