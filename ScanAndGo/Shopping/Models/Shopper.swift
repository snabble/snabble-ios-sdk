//
//  Shopper.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 24.06.24.
//

import SwiftUI
import OSLog
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
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

/// Manages a shopping session in a shop and coordinates the shopping cart.
///
/// The `Shopper` class is responsible for handling the shopping experience in a specific shop. It
/// manages the shopping cart, payment methods, and coordinates with the `BarcodeManager` to handle
/// barcode scanning and product identification.
///
/// The class conforms to `ObservableObject` to support SwiftUI views and implements the
/// `BarcodeProcessing` and `Equatable` protocols. It handles actions such as starting and stopping
/// the barcode scanner, processing scanned items, and managing payment methods.
///
/// Example usage:
/// ```swift
/// let shop = Shop(...)
/// let shopper = Shopper(shop: shop)
/// shopper.startScanner()
/// ```
@dynamicMemberLookup
public final class Shopper: ObservableObject, BarcodeProcessing, Equatable {
    public static func == (lhs: Shopper, rhs: Shopper) -> Bool {
        lhs.barcodeManager.shop == rhs.barcodeManager.shop
    }
    
    /// Manages the barcode scanning process.
    /// The `barcodeManager` is responsible for handling scanned barcodes, managing the scanner state, and processing scanned items.
    @ObservedObject public var barcodeManager: BarcodeManager
    
    /// Manages the shopping cart.
    /// The `cartModel` handles the items in the shopping cart, including adding, removing, and updating items.
    @ObservedObject public var cartModel: ShoppingCartViewModel
    
    /// Manages the available payment methods.
    /// The `paymentManager` keeps track of available and selected payment methods for the current shopping session.
    @Published public var paymentManager: PaymentMethodManager
    
    /// Indicates whether the shopper has a valid payment method.
    /// This property is set to `true` when a valid payment method is selected, and `false` otherwise.
    @Published public var hasValidPayment: Bool = false
    
    /// A list of payment methods that are restricted for the shopper.
    public var restrictedPayments: [RawPaymentMethod] = []
    
    /// Provides a dynamic member lookup for retrieving payment icons.
    ///
    /// - Parameter member: The member name to lookup.
    /// - Returns: The payment icon if available, otherwise nil.
   subscript(dynamicMember member: String) -> UIImage? {
        if member == "paymentIcon", hasValidPayment  {
            return paymentManager.selectedPayment?.method.icon
        }
        return nil
    }

    let logger = Logger(subsystem: "ScanAndGo", category: "Shopper")
    private var subscriptions = Set<AnyCancellable>()
    
    /// Initializes a new Shopper with the specified shop and barcode detector.
    ///
    /// - Parameters:
    ///   - shop: The shop for the Shopper.
    ///   - detector: The barcode detector used for scanning.
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
        
        self.paymentManager.$selectedPayment
            .receive(on: RunLoop.main)
            .sink { [unowned self] payment in
                self.verifyPayment(payment)
            }
            .store(in: &subscriptions)
        
        ActionManager.shared.$actionState
            .receive(on: RunLoop.main)
            .sink { [unowned self] action in
                self.handleAction(action)
            }
            .store(in: &subscriptions)
    }
    
    /// Handles actions based on the new state.
    ///
    /// - Parameter newState: The new action state.
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
    
    /// Indicates whether scanning is activated.
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
    
    /// Indicates whether scanning is paused. Stored in UserDefaults.
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
    /// Indicates whether the Shopper is currently processing.
    @Published public var processing: Bool = false
    
    /// The scanned item recognized by the BarcodeManager.
    @Published public var scannedItem: BarcodeManager.ScannedItem? {
        didSet {
            if scannedItem != nil {
                stopScanner()
                processing = false
            }
        }
    }
    /// A list of scanned items.
    @Published public var bundles: [BarcodeManager.ScannedItem] = []
    
    /// The scan message received from BarcodeProcessing.
    @Published public var scanMessage: ScanMessage?
    
    /// The error message received from BarcodeProcessing.
    @Published public var errorMessage: String?
    
    @Published public var flashlight: Bool = false {
        didSet {
            barcodeManager.barcodeDetector.setTorch(flashlight)
        }
    }
    @Published public var isNavigating: Bool = false {
        didSet {
            if isNavigating == false {
                controller = nil
                self.startScanner()
            }
        }
    }
    @Published public var controller: UIViewController? {
        didSet {
            if controller != nil {
                self.stopScanner()
                isNavigating = true
            }
        }
    }
    
    /// Resets the scan data.
    public func reset() {
        self.errorMessage = nil
        self.scanMessage = nil
        self.scannedItem = nil
        self.bundles = []
    }
    /// Indicates whether the scanner is ready to scan.
    public var readyToScan: Bool {
        scanningActivated && !scanningPaused
    }
    
    /// Starts the barcode scanner.
    @MainActor
    public func startScanner() {
        guard readyToScan, barcodeManager.barcodeDetector.state != .scanning else {
            return
        }
        self.reset()
        barcodeManager.barcodeDetector.start()
    }
    
    /// Stops the barcode scanner.
    @MainActor
    public func stopScanner() {
        barcodeManager.barcodeDetector.stop()
    }
}

extension Shopper: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(barcodeManager.shop.id)
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
        logger.debug("no implementation: gotoScanner()")
    }
}

extension Shopper: MessageDelegate {
    public func showInfoMessage(_ message: String) {
        logger.debug("showInfoMessage: \(message)")
        sendAction(.toast(Toast(message: message)))
    }
    
    public func showWarningMessage(_ message: String) {
        logger.debug("showWarningMessage: \(message)")
        sendAction(.toast(Toast(message: message, style: .warning)))
    }
}
