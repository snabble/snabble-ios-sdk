//
//  BarcodeManager.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 13.06.24.
//

import SwiftUI
import OSLog

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI
import Combine

/// Protocol for processing scanned barcodes.
public protocol BarcodeProcessing: AnyObject, AnalyticsDelegate {
    var processing: Bool { get set }
    var scannedItem: BarcodeManager.ScannedItem? { get set }
    var bundles: [BarcodeManager.ScannedItem] { get set }
    var scanMessage: ScanMessage? { get set }
    var errorMessage: String? { get set }
}

/// Manages barcode scanning and processing for a shopping session.
///
/// The `BarcodeManager` class is responsible for handling barcode scanning using the device's camera.
/// It uses an `InternalBarcodeDetector` to detect barcodes and processes them to identify products.
/// Upon successful barcode detection, it communicates with the `Shopper` class to update the shopping cart.
/// It also handles various messages such as product not found, age restrictions, and errors.
///
/// Example usage:
/// ```swift
/// let shop = Shop(...)
/// let shoppingCart = ShoppingCart(...)
/// let detector = InternalBarcodeDetector(...)
/// let barcodeManager = BarcodeManager(shop: shop, shoppingCart: shoppingCart, detector: detector)
/// ```
@Observable @MainActor
public final class BarcodeManager {
    let shop: Shop
    let shoppingCart: ShoppingCart
    let project: Project
    let productProvider: ProductProviding
    let logger = Logger(subsystem: "io.snabble.sdk.ScanAndGo", category: "ShoppingManager")
    
    /// Represents a scanned item.
    public struct ScannedItem: Equatable {
        public static func == (lhs: BarcodeManager.ScannedItem, rhs: BarcodeManager.ScannedItem) -> Bool {
            lhs.code == rhs.code &&
            lhs.type == rhs.type
        }
        let scannedProduct: ScannedProduct
        let code: String
        let type: ProductType
        
        /// The product corresponding to the scanned item.
        public var product: Product {
            scannedProduct.product
        }
        /// The name of the product.
        public var productName: String {
            product.name
        }
    }
    
    let tapticFeedback = UINotificationFeedbackGenerator()
    public let barcodeDetector: InternalBarcodeDetector
    
    public weak var scannerDelegate: ScannerDelegate?
    public weak var processingDelegate: BarcodeProcessing?
    
    private var subscriptions = Set<AnyCancellable>()
    
    /// Initializes a new BarcodeManager with the specified shop, shopping cart, and barcode detector.
    ///
    /// - Parameters:
    ///   - shop: The shop for the BarcodeManager.
    ///   - shoppingCart: The shopping cart associated with the shop.
    ///   - detector: The barcode detector used for scanning.
    public init(shop: Shop,
                shoppingCart: ShoppingCart,
                detector: InternalBarcodeDetector
    ) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        
        let project = shop.project ?? .none
        self.project = project
        self.productProvider = Snabble.shared.productProvider(for: project)
        
        self.barcodeDetector = detector
        self.barcodeDetector.scanFormats = project.scanFormats
        
        self.barcodeDetector.barcodePublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] barcode in
                self.logger.debug("received barcode: \(barcode.description)")
                self.handleScannedCode(barcode.code, withFormat: barcode.format)
            }
            .store(in: &subscriptions)
    }
}
