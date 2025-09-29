//
//  CheckModel.swift
//  
//
//  Created by Uwe Tilemann on 07.02.23.
//

import UIKit
import SnabbleCore
import Combine
import SnabbleAssetProviding

@MainActor
public protocol CheckViewModel {
    var checkModel: CheckModel { get }
    var codeImage: UIImage? { get }
    var headerImage: UIImage? { get set }
}

@MainActor
public protocol CheckViewModelProviding {
    var viewModel: CheckViewModel? { get }
}

@MainActor
public protocol CheckoutProcessing {
    var checkoutProcess: CheckoutProcess { get }
    var shoppingCart: ShoppingCart { get }
    var shop: Shop { get }
    var paymentDelegate: PaymentDelegate? { get }
}

@MainActor
public protocol CheckModelDelegate: AnyObject {
    func checkoutRejected(process: CheckoutProcess)
    func checkoutFinalized(process: CheckoutProcess)
    func checkoutAborted(process: CheckoutProcess)
}

public final class CheckModel: CheckoutProcessing, CheckModelDelegate, @unchecked Sendable {
    
    public private(set) var checkoutProcess: CheckoutProcess
    public let shoppingCart: ShoppingCart
    public let shop: Shop
    
    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?
    
    public weak var paymentDelegate: PaymentDelegate?
    public weak var delegate: CheckModelDelegate?
    
    public var continuation: ((_ process: CheckoutProcess) -> CheckModel.CheckResult)?
    
    public init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess, paymentDelegate: PaymentDelegate?) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess
        self.paymentDelegate = paymentDelegate
    }
    
    public func startCheck() {
        startTimer()
    }
    
    // MARK: - polling timer
    private func startTimer() {
        self.processTimer?.invalidate()
        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            Task { @MainActor in
                let project = SnabbleCI.project
                self.checkoutProcess.update(project,
                                            taskCreated: { task in
                                                Task { @MainActor in
                                                    self.sessionTask = task
                                                }
                                            },
                                            completion: { result in
                                                Task { @MainActor in
                                                    self.update(result)
                                                }
                                            })
            }
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
    public enum CheckResult {
        case continuePolling
        case rejectCheckout
        case finalizeCheckout
    }
    
    public func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        guard let continuation = self.continuation else {
            fatalError("continuation(_ process:CheckoutProcess) must be set")
        }
        return continuation(process)
    }
    
    public func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutRejected(process: process)
    }
    
    public func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutFinalized(process: process)
    }
    
    public func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        Snabble.clearInFlightCheckout()
        self.shoppingCart.generateNewUUID()
        delegate?.checkoutAborted(process: process)
    }
    
    public func cancelPayment() {
        guard processTimer != nil else { return }
        
        self.paymentDelegate?.track(.paymentCancelled)
        self.stopTimer()

        self.checkoutProcess.abort(SnabbleCI.project) { result in
            Task { @MainActor in
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
    
    func assetPublisher() -> AnyPublisher<UIImage?, Never> {
        let asset = self.asset

        return Future<UIImage?, Never> { promise in
            Task {
                let image = await self.getAsset(asset)
                promise(.success(image))
            }
        }
        .eraseToAnyPublisher()
    }

    private func getAsset(_ asset: (imageAsset: ImageAsset, bundlePath: String)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            SnabbleCI.getAsset(asset.imageAsset, bundlePath: asset.bundlePath) { img in
                continuation.resume(returning: img)
            }
        }
    }
}
