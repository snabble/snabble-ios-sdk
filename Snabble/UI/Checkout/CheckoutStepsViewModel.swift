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
    private(set) var checkoutProcess: CheckoutProcess
    let shoppingCart: ShoppingCart

    private weak var checkoutProcessTimer: Timer?
    private var processSessionTask: URLSessionDataTask?

    weak var delegate: CheckoutStepsViewModelDelegate?

    init(checkoutProcess: CheckoutProcess, shoppingCart: ShoppingCart) {
        self.checkoutProcess = checkoutProcess
        self.shoppingCart = shoppingCart
        updateViewModels(with: checkoutProcess)
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
            checkoutProcess = process
            updateViewModels(with: process)
            updateShoppingCart(for: process)
            continuePolling = shouldContinuePolling(for: process)
        case let .failure(error):
            Log.error(String(describing: error))
            continuePolling = true
        }

        if continuePolling {
            startTimer()
        }
    }

    private func updateShoppingCart(for checkoutProcess: CheckoutProcess) {
        switch checkoutProcess.paymentState {
        case .successful:
            shoppingCart.removeAll(endSession: true, keepBackup: false)
        case .failed:
            shoppingCart.generateNewUUID()
        case .pending:
            if checkoutProcess.fulfillments.containsFailureState {
                shoppingCart.generateNewUUID()
            }
        case .transferred, .processing, .unauthorized, .unknown:
            break
        }
    }

    private func updateViewModels(with checkoutProcess: CheckoutProcess) {
        steps = steps(for: checkoutProcess)
        headerViewModel = steps.checkoutStepStatus
    }

    private func steps(for checkoutProcess: CheckoutProcess) -> [CheckoutStep] {
        var steps: [CheckoutStep] = [
            .init(paymentState: checkoutProcess.paymentState)
        ]

        steps.append(contentsOf: checkoutProcess.fulfillments.map(CheckoutStep.init))

        if let exitToken = checkoutProcess.exitToken {
            steps.append(CheckoutStep(exitToken: exitToken))
        }

        if let link = checkoutProcess.links.receipt {
            steps.append(CheckoutStep(receiptLink: link))
        }

        return steps
    }

    private func shouldContinuePolling(for checkoutProcess: CheckoutProcess) -> Bool {
        var shouldContinuePolling: Bool
        switch checkoutProcess.paymentState {
        case .successful:
            shouldContinuePolling = false
        case .failed:
            shouldContinuePolling = false
        case .pending:
            shouldContinuePolling = !checkoutProcess.fulfillments.containsFailureState
        case .transferred, .processing, .unauthorized, .unknown:
            shouldContinuePolling = true
        }

        if checkoutProcess.requiresExitToken && checkoutProcess.exitToken?.image == nil {
            shouldContinuePolling = true
        }
        return shouldContinuePolling
    }

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

private extension Array where Element == Fulfillment {
    var containsFailureState: Bool {
        !FulfillmentState.failureStates.isDisjoint(with: Set(map { $0.state }))

    }
}
