//
//  CheckModel.swift
//  
//
//  Created by Uwe Tilemann on 07.02.23.
//

import UIKit
import SnabbleCore
import Combine

protocol CheckViewModel {
    var checkModel: CheckModel { get }
    var codeImage: UIImage? { get }
}

protocol CheckoutProcessing {
    var checkoutProcess: CheckoutProcess { get }
    var shoppingCart: ShoppingCart { get }
    var shop: Shop { get }
    var paymentDelegate: PaymentDelegate? { get }
}

protocol CheckModelDelegate: AnyObject {
    func checkoutRejected(process: CheckoutProcess)
    func checkoutFinalized(process: CheckoutProcess)
    func checkoutAborted(process: CheckoutProcess)
}

final class CheckModel: CheckoutProcessing, CheckModelDelegate {
    
    private(set) var checkoutProcess: CheckoutProcess
    let shoppingCart: ShoppingCart
    let shop: Shop
    
    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?
    
    weak var paymentDelegate: PaymentDelegate?
    weak var delegate: CheckModelDelegate?
    
    var continuation: ((_ process: CheckoutProcess) -> CheckModel.CheckResult)?
    
    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess
    }
    
    func startCheck() {
        startTimer()
    }
    
    // MARK: - polling timer
    private func startTimer() {
        self.processTimer?.invalidate()
        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let project = SnabbleCI.project
            self.checkoutProcess.update(project,
                                        taskCreated: { self.sessionTask = $0 },
                                        completion: { self.update($0) })
        }
    }
    
    private func stopTimer() {
        self.processTimer?.invalidate()
        self.processTimer = nil
        
        self.sessionTask?.cancel()
        self.sessionTask = nil
    }
    
    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        switch result.result {
        case .success(let process):
            checkoutProcess = process
            
            switch checkContinuation(for: process) {
            case .continuePolling:
                self.startTimer()
            case .rejectCheckout:
                self.checkoutRejected(process: process)
            case .finalizeCheckout:
                self.checkoutFinalized(process: process)
            }
            
        case .failure(let error):
            Log.error(String(describing: error))
        }
    }
    
    // MARK: - process updates
    enum CheckResult {
        case continuePolling
        case rejectCheckout
        case finalizeCheckout
    }
    
    func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        guard let continuation = self.continuation else {
            fatalError("continuation(_ process:CheckoutProcess) must be set")
        }
        return continuation(process)
    }
    
    func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutRejected(process: process)
    }
    
    func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutFinalized(process: process)
    }
    
    func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        Snabble.clearInFlightCheckout()
        self.shoppingCart.generateNewUUID()
        delegate?.checkoutAborted(process: process)
    }
    
    func cancelPayment() {
        self.paymentDelegate?.track(.paymentCancelled)
        self.stopTimer()
        
        self.checkoutProcess.abort(SnabbleCI.project) { result in
            switch result {
            case .success(let process):
                self.checkoutAborted(process: process)
            case .failure:
                let alertView = AlertView(title: Asset.localizedString(forKey: "Snabble.Payment.CancelError.title"),
                                          message: Asset.localizedString(forKey: "Snabble.Payment.CancelError.message"))
                alertView.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
                    self.startTimer()
                })
                alertView.show()
            }
        }
    }
}

extension CheckModel {
    var codeContent: String {
        switch checkoutProcess.rawPaymentMethod {
        case .gatekeeperTerminal:
            let handoverInformation = checkoutProcess.paymentInformation?.handoverInformation
            return handoverInformation ?? "snabble:checkoutProcess:\(checkoutProcess.id)"
        default:
            return checkoutProcess.id
        }
    }
}

extension CheckModel {
    var asset: (imageAsset: ImageAsset, bundlePath: String) {
        let asset: ImageAsset
        let bundlePath: String
        switch checkoutProcess.rawPaymentMethod {
        case .qrCodeOffline, .customerCardPOS:
            asset = .checkoutOffline
            bundlePath = "Checkout/\(SnabbleCI.project.id)/checkout-offline"
        default:
            asset = .checkoutOnline
            bundlePath = "Checkout/\(SnabbleCI.project.id)/checkout-online"
        }
        return (asset, bundlePath)
    }
    
    func assetPublisher() -> AnyPublisher<UIImage?, Never>  {
        Future<UIImage?, Never> { promise in
            let asset = self.asset
            
            SnabbleCI.getAsset(asset.imageAsset, bundlePath: asset.bundlePath) { img in
                promise(.success(img))
            }
        }
        .eraseToAnyPublisher()
    }
}
