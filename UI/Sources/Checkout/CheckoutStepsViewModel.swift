//
//  CheckoutStepsViewModel.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.10.21.
//

import Foundation
import SnabbleCore

protocol CheckoutStepsViewModelDelegate: AnyObject {
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateCheckoutProcess checkoutProcess: CheckoutProcess)
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateHeaderViewModel headerViewModel: CheckoutHeaderViewModel)
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateSteps steps: [CheckoutStep])
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateExitToken exitToken: ExitToken)
}

final class CheckoutStepsViewModel: @unchecked Sendable {
    private(set) var checkoutProcess: CheckoutProcess? {
        didSet {
            if let checkoutProcess = checkoutProcess {
                delegate?.checkoutStepsViewModel(self, didUpdateCheckoutProcess: checkoutProcess)
                if let exitToken = checkoutProcess.exitToken {
                    delegate?.checkoutStepsViewModel(self, didUpdateExitToken: exitToken)
                }
            }
        }
    }
    let shoppingCart: ShoppingCart
    let shop: Shop

    private weak var checkoutProcessTimer: Timer?
    private var processSessionTask: URLSessionDataTask?

    weak var delegate: CheckoutStepsViewModelDelegate?

    private let originPoller: OriginPoller

    var savedIbans = Set<String>()
    private(set) var originCandidate: OriginCandidate? {
        didSet {
            updateViewModels(with: checkoutProcess)
        }
    }

    init(shop: Shop, checkoutProcess: CheckoutProcess?, shoppingCart: ShoppingCart) {
        self.shop = shop
        self.checkoutProcess = checkoutProcess
        self.shoppingCart = shoppingCart
        self.originPoller = OriginPoller(project: shop.project!)
        updateViewModels(with: checkoutProcess)
    }

    func startTimer() {
        checkoutProcessTimer?.invalidate()
        checkoutProcessTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let project = self?.shop.project else { return }
            self?.checkoutProcess?.update(project,
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

    func update() {
        updateViewModels(with: checkoutProcess)
    }

    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        var continuePolling: Bool

        switch result.result {
        case let .success(process):
            continuePolling = !process.isComplete
            checkoutProcess = process
            updateViewModels(with: process)
            updateShoppingCart(for: process)
            startOriginPollerIfNeeded(for: process)
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
        case .successful, .transferred:
            shoppingCart.removeAll(endSession: true, keepBackup: false)
        case .failed:
            shoppingCart.generateNewUUID()
        case .pending:
            if checkoutProcess.fulfillments.containsFailureState {
                shoppingCart.generateNewUUID()
            }
        case .processing, .unauthorized, .unknown:
            break
        }
    }

    private func updateViewModels(with checkoutProcess: CheckoutProcess?) {
        steps = steps(for: checkoutProcess)
        headerViewModel = steps.checkoutStepStatus
    }

    private func steps(for checkoutProcess: CheckoutProcess?) -> [CheckoutStep] {
        guard let checkoutProcess = checkoutProcess else {
            return []
        }

        var steps = [CheckoutStep]()

        let paymentState = checkoutProcess.paymentState
        switch checkoutProcess.rawPaymentMethod {
        case .qrCodeOffline:
            break
        default:
            steps.append(.init(paymentState: checkoutProcess.aborted ? .failed : paymentState))
        }

        let fulfillmentSteps = checkoutProcess.fulfillments.map({ fulfillment in
            CheckoutStep(fulfillment: fulfillment, paymentState: paymentState)
        })
        steps.append(contentsOf: fulfillmentSteps)

        if let exitToken = checkoutProcess.exitToken {
            steps.append(CheckoutStep(exitToken: exitToken, paymentState: paymentState))
        }

        if let receipt = checkoutProcess.links.receipt {
            steps.append(CheckoutStep(receiptLink: receipt, paymentState: paymentState))
        }

        if let originCandidate = originCandidate, originCandidate.isValid {
            steps.append(CheckoutStep(originCandidate: originCandidate, savedIbans: savedIbans))
        }

        return steps
    }

    private func startOriginPollerIfNeeded(for checkoutProcess: CheckoutProcess) {
        if originPoller.shouldStart(for: checkoutProcess) {
            originPoller.delegate = self
            originPoller.start(for: checkoutProcess)
        }
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

extension CheckoutStepsViewModel: OriginPollerDelegate {
    func originPoller(_ originPoller: OriginPoller, didReceiveCandidate originCandidate: OriginCandidate) {
        self.originCandidate = originCandidate
    }
}
