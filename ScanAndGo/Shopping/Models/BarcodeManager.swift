//
//  BarcodeManager.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 13.06.24.
//

import SwiftUI
import OSLog

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI
import Combine

public protocol BarcodeProcessing: AnyObject, AnalyticsDelegate {
    var processing: Bool { get set }
    var scannedItem: BarcodeManager.ScannedItem? { get set }
    var bundles: [BarcodeManager.ScannedItem] { get set }
    var scanMessage: ScanMessage? { get set }
    var errorMessage: String? { get set }
}

public final class BarcodeManager: ObservableObject {
    let shop: Shop
    let shoppingCart: ShoppingCart
    let project: Project
    let productProvider: ProductProviding
    let logger = Logger(subsystem: "ScanAndGo", category: "ShoppingManager")
    
    public struct ScannedItem: Equatable {
        public static func == (lhs: BarcodeManager.ScannedItem, rhs: BarcodeManager.ScannedItem) -> Bool {
            lhs.code == rhs.code &&
            lhs.type == rhs.type
        }
        let scannedProduct: ScannedProduct
        let code: String
        let type: ProductType
        
        public var product: Product {
            scannedProduct.product
        }
        public var productName: String {
            product.name
        }
    }
    
    let tapticFeedback = UINotificationFeedbackGenerator()
    public let barcodeDetector: InternalBarcodeDetector
    
    public weak var scannerDelegate: ScannerDelegate?
    public weak var processingDelegate: BarcodeProcessing?
    
    private var subscriptions = Set<AnyCancellable>()
    
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
        
        self.barcodeDetector.$scannedBarcode
            .receive(on: RunLoop.main)
            .sink { [unowned self] barcode in
                if let barcode {
                    self.logger.debug("received barcode: \(barcode.description)")
                    self.handleScannedCode(barcode.code, withFormat: barcode.format)
                }
            }
            .store(in: &subscriptions)
    }
}
