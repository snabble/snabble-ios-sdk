//
//  ShoppingModel.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 24.06.24.
//

import SwiftUI
import OSLog
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

extension UserDefaults {
    public static let scanningDisabledKey: String = "io.snabble.sdk.scanningDisabled"
    
    public var scanningDisabled: Bool {
        bool(forKey: Self.scanningDisabledKey)
    }
    
    public func setScanningDisabled(_ flag: Bool) {
        setValue(flag, forKey: Self.scanningDisabledKey)
    }
}

public protocol ShoppingProvider: AnyObject {
    var shopper: Shopper { get }
}

public final class Shopper: ObservableObject, BarcodeProcessing, Equatable {
    public static func == (lhs: Shopper, rhs: Shopper) -> Bool {
        lhs.barcodeManager.shop == rhs.barcodeManager.shop
    }
    
    @ObservedObject public var barcodeManager: BarcodeManager
    @ObservedObject public var cartModel: ShoppingCartViewModel
    
    @Published public var paymentManager: PaymentMethodManager
    @Published public var selectedPayment: Payment?
    
    let logger = Logger(subsystem: "ScanAndGo", category: "Shopper")
    
    private var subscriptions = Set<AnyCancellable>()
    public var restrictedPayments: [RawPaymentMethod] = []
    
    public init(shop: Shop, detector: InternalBarcodeDetector = .init(detectorArea: .rectangle)) {
        let shoppingCart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
        let barcodeManager = BarcodeManager(shop: shop,
                                            shoppingCart: shoppingCart,
                                            detector: detector)
        
        self.barcodeManager = barcodeManager
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
        self.paymentManager = PaymentMethodManager(shoppingCart: shoppingCart)
        
        self.cartModel.shoppingCartDelegate = self
        self.barcodeManager.processingDelegate = self
        
        self.paymentManager.delegate = self
        self.selectedPayment = self.paymentManager.selectedPayment
        
        ActionManager.shared.$actionState
            .receive(on: RunLoop.main)
            .sink { [unowned self] action in
                self.handleAction(action)
            }
            .store(in: &subscriptions)
    }
    
    private func handleAction(_ newState: ActionType) {
        if case .idle = newState {
            startScanner()
        } else {
            if case.alertSheet = newState {
                logger.debug("Don't stop scanner while showing alertSheet")
            } else {
                stopScanner()
            }
        }
    }
    
    /// To begin a scanning session set `scanningActivated` to `true`
    @Published public var scanningActivated: Bool = false {
        didSet {
            logger.debug("scanningActivated \(self.scanningActivated)")
            if scanningActivated {
                startScanner()
            } else {
                stopScanner()
            }
        }
    }
    
    /// stored in UserDefaults
    @Published public var scanningPaused: Bool = UserDefaults.standard.scanningDisabled {
        didSet {
            logger.debug("scanningDisabled \(self.scanningPaused)")
            if scanningPaused {
                stopScanner()
            } else {
                startScanner()
            }
            UserDefaults.standard.setScanningDisabled(scanningPaused)
        }
    }
    /// While fetching data `processing` this is `true`
    @Published public var processing: Bool = false
    
    /// Publishing the `scannedItem` that was recognized by `barcodeManager`
    @Published public var scannedItem: BarcodeManager.ScannedItem? {
        didSet {
            if scannedItem != nil {
                stopScanner()
                processing = false
            }
        }
    }
    @Published public var bundles: [BarcodeManager.ScannedItem] = []
    
    /// `ScanMessage` message received from `BarcodeProcessing
    @Published public var scanMessage: ScanMessage?
    
    /// Error message received from `BarcodeProcessing`
    @Published public var errorMessage: String? 
    
    @Published public var flashlight: Bool = false {
        didSet {
            barcodeManager.barcodeDetector.setTorch(flashlight)
        }
    }
    @Published public var controller: UIViewController?
    
    public func reset() {
        self.errorMessage = nil
        self.scanMessage = nil
        self.scannedItem = nil
        self.bundles = []
    }
    public var readyToScan: Bool {
        scanningActivated && !scanningPaused
    }
    
    @MainActor
    public func startScanner() {
        guard readyToScan, barcodeManager.barcodeDetector.state != .scanning else {
            return
        }
        self.reset()
        barcodeManager.barcodeDetector.start()
    }
    
    @MainActor
    public func stopScanner() {
        barcodeManager.barcodeDetector.stop()
    }
}

extension Shopper: AnalyticsDelegate {
    public func track(_ event: SnabbleCore.AnalyticsEvent) {
        self.logger.debug("**TODO** track event.")
        print("event", event)
    }
}

extension Shopper: ShoppingCartDelegate {
    public func gotoPayment(
        _ method: SnabbleCore.RawPaymentMethod,
        _ detail: SnabbleCore.PaymentMethodDetail?,
        _ info: SnabbleCore.SignedCheckoutInfo,
        _ cart: SnabbleCore.ShoppingCart,
        _ didStartPayment: @escaping (Bool) -> Void) {
            
            logger.debug("starting PaymentProcess: \(method.displayName)")
            
            let process = PaymentProcess(info, cart, shop: barcodeManager.shop)
            process.paymentDelegate = self
            process.start(method, detail) { result in
                switch result {
                case .success(let viewController):
                    // self.sendAction(.controller(viewController))
                    self.controller = viewController
                    
                case .failure(let error):
                    self.showWarningMessage("Error creating payment process: \(error))")
                }
            }
            
        }
    
    public func gotoScanner() {
        logger.debug("**: gotoScanner()")
    }
}

extension Shopper: MessageDelegate {
    public func showInfoMessage(_ message: String) {
        logger.debug("showInfoMessage: \(message)")
        sendAction(.toast(Toast(text: message)))
    }
    
    public func showWarningMessage(_ message: String) {
        logger.debug("showWarningMessage: \(message)")
        sendAction(.toast(Toast(text: message, style: .warning)))
    }
}
