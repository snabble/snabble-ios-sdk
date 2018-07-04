//
//  PaymentProcessPoller.swift
//  Snabble
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

class PaymentProcessPoller {
    private var timer: Timer?
    private var process: CheckoutProcess
    private var task: URLSessionDataTask?
    private var completion: ((Bool) -> ())?

    init(_ process: CheckoutProcess) {
        self.process = process
    }

    func waitForApproval(completion: @escaping (Bool) -> () ) {
        self.completion = completion
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkApproval(timer)
        }
    }

    func waitForPayment(completion: @escaping (Bool) -> () ) {
        self.completion = completion
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkPayment(timer)
        }
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

    private func checkApproval(_ timer: Timer) {
        print("checking approval...")

        self.task = self.process.update { process, error in
            guard
                let process = process,
                let paymentApproval = process.paymentApproval,
                let supervisorApproval = process.supervisorApproval
            else {
                return
            }

            self.timer?.invalidate()
            self.timer = nil

            self.completion?(paymentApproval && supervisorApproval)
        }
    }

    private func checkPayment(_ timer: Timer) {
        print("checking payment...")

        self.task = self.process.update { process, error in
            guard let process = process, process.paymentState != .pending else {
                return
            }

            self.timer?.invalidate()
            self.timer = nil

            self.completion?(process.paymentState == .successful)
        }
    }

}
