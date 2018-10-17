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
    private var project: Project
    private var task: URLSessionDataTask?
    private var completion: ((Bool) -> ())?

    init(_ process: CheckoutProcess, _ project: Project) {
        self.process = process
        self.project = project
    }

    func waitForApproval(completion: @escaping (Bool) -> () ) {
        self.completion = completion
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkApproval()
        }
    }

    func waitForPayment(completion: @escaping (Bool) -> () ) {
        self.completion = completion
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkPayment()
        }
    }

    func waitForReceipt(_ shopName: String, completion: @escaping (Bool) -> () ) {
        self.completion = completion
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkReceipt(shopName)
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

    private func checkApproval() {
        print("checking approval...")
        self.process.update(self.project, taskCreated: { self.task = $0 }) { process, error in
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

    private func checkPayment() {
        print("checking payment...")

        self.process.update(self.project, taskCreated: { self.task = $0 }) { process, error in
            guard let process = process, process.paymentState != .pending else {
                return
            }

            self.timer?.invalidate()
            self.timer = nil

            self.completion?(process.paymentState == .successful)
        }
    }

    private func checkReceipt(_ shopName: String) {
        print("checking receipt...")

        self.process.update(project, taskCreated: { self.task = $0 }) { process, error in
            guard let process = process, process.links.receipt != nil else {
                return
            }

            self.timer?.invalidate()
            self.timer = nil

            // download the receipt
            ReceiptsManager.shared.download(process, self.project, shopName)

            self.completion?(true)
        }
    }

}
