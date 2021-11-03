//
//  CheckoutStepsViewModel.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.10.21.
//

import Foundation

protocol CheckoutStepsViewModelDelegate: AnyObject {
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateHeaderViewModel headerViewModel: CheckoutHeaderViewModel)
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateSteps steps: [CheckoutStep])
}

class CheckoutStepsViewModel {
    let checkoutProcess: CheckoutProcess

    private weak var checkoutProcessTimer: Timer?
    private var processSessionTask: URLSessionDataTask?

    weak var delegate: CheckoutStepsViewModelDelegate?

    init(checkoutProcess: CheckoutProcess) {
        self.checkoutProcess = checkoutProcess
        update(with: checkoutProcess)
    }

    func startTimer() {
        checkoutProcessTimer?.invalidate()
        checkoutProcessTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            let project = SnabbleUI.project
            self?.checkoutProcess.update(project,
                                         taskCreated: { [weak self] in
                self?.processSessionTask = $0
            },
                                         completion: { [weak self] result in
                self?.update(result)
            })
        }
    }

    func stopTimer() {
        checkoutProcessTimer?.invalidate()

        processSessionTask?.cancel()
        processSessionTask = nil
    }

    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        var continuePolling: Bool
        switch result.result {
        case let .success(process):
            update(with: process)
            continuePolling = shouldContinuePolling(for: process)
        case let .failure(error):
            Log.error(String(describing: error))
            continuePolling = true
        }

        if continuePolling {
            startTimer()
        }
    }

    private func update(with checkoutProcess: CheckoutProcess) {
        headerViewModel = CheckoutStepStatus.from(paymentState: checkoutProcess.paymentState)
        steps = steps(for: checkoutProcess)
    }

    private func steps(for checkoutProcess: CheckoutProcess) -> [CheckoutStep] {
        var steps: [CheckoutStep] = [
            .init(paymentState: checkoutProcess.paymentState)
        ]

        steps.append(contentsOf: checkoutProcess.fulfillments.map(CheckoutStep.init))

        if let exitToken = checkoutProcess.exitToken {
            steps.append(CheckoutStep(exitToken: exitToken))
        }

        return steps
    }

    private func shouldContinuePolling(for checkoutProcess: CheckoutProcess) -> Bool {
        var shouldContinuePolling = true
        switch checkoutProcess.paymentState {
        case .successful, .failed:
            shouldContinuePolling = false
        case .pending:
            let states = Set(checkoutProcess.fulfillments.map { $0.state })
            if FulfillmentState.failureStates.isDisjoint(with: states) == false {
                shouldContinuePolling = false
            } else {
                shouldContinuePolling = true
            }
        case .transferred, .processing, .unauthorized, .unknown: ()
            shouldContinuePolling = true
        }

        if checkoutProcess.requiresExitToken && checkoutProcess.exitToken?.image == nil {
            shouldContinuePolling = true
        }
        return shouldContinuePolling
    }

//    private func updateView(_ process: CheckoutProcess, _ rawJson: [String: Any]?) -> Bool {
//        // figure out failure conditions first
//        let approvalDenied = process.supervisorApproval == false || process.paymentApproval == false
//        let checkFailed = process.checks.first { $0.state == .failed } != nil
//        if approvalDenied || checkFailed {
//            self.paymentFinished(false, process, rawJson)
//            return false
//        }
//
//        if let candidateLink = process.paymentResult?["originCandidateLink"] as? String {
//            OriginPoller.shared.startPolling(SnabbleUI.project, candidateLink)
//        }
//
//        let failureCause = FailureCause(rawValue: process.paymentResult?["failureCause"] as? String ?? "")
//
//        self.updateQRCode(process)
//
//        switch process.paymentState {
//        case .successful:
//            self.paymentFinished(true, process, rawJson)
//            return false
//        case .failed:
//            if failureCause == .terminalAbort {
//                self.paymentCancelled()
//            } else {
//                self.paymentFinished(false, process, rawJson)
//            }
//            return false
//        case .pending:
//            let states = Set(process.fulfillments.map { $0.state })
//            if !FulfillmentState.failureStates.isDisjoint(with: states) {
//                self.paymentFinished(false, process, rawJson)
//                return false
//            }
//            return true
//        case .transferred, .processing, .unauthorized, .unknown: ()
//            return true
//        }
//    }

    var headerViewModel: CheckoutHeaderViewModel = CheckoutStepStatus.loading {
        didSet {
            delegate?.checkoutStepsViewModel(self, didUpdateHeaderViewModel: headerViewModel)
        }
    }

    var steps: [CheckoutStep] = [] {
        didSet {
            delegate?.checkoutStepsViewModel(self, didUpdateSteps: steps)
        }
    }
}
