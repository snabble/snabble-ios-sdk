//
//  ShoppingManager+LookupCode.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 16.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

enum ScannerLookup {
    case product(ScannedProduct)
    case coupon(Coupon, String)
    case voucher(Voucher)
    case failure(ProductLookupError)
}

extension BarcodeResult: Equatable {
    public static func == (lhs: BarcodeResult, rhs: BarcodeResult) -> Bool {
        lhs.code == rhs.code && lhs.format == rhs.format
    }
}

extension ScanMessage: Equatable {
    public static func == (lhs: ScanMessage, rhs: ScanMessage) -> Bool {
        lhs.text == rhs.text
    }
}

extension BarcodeManager.ScannedItem: CustomStringConvertible {
    public var description: String {
        "\(type) \(scannedProduct.product.name) \(code)"
    }
}

extension BarcodeManager: BarcodeScanning {
    public func scannedCodeResult(_ result: SnabbleUI.BarcodeResult) {
        self.handleScannedCode(result.code, withFormat: result.format)
    }
}

extension BarcodeManager {
    private func scannedUnknown(messageText: String, code: String) {
        self.logger.debug("scanned unknown code \(code)")
        self.tapticFeedback.notificationOccurred(.error)
        
        self.processingDelegate?.scanMessage = ScanMessage(messageText)
        self.processingDelegate?.track(.scanUnknown(code))
    }
    
    /// Handles the scanned barcode and looks up the corresponding product.
    ///
    /// - Parameters:
    ///   - code: The scanned barcode.
    ///   - format: The format of the scanned barcode.
    func handleScannedCode(_ scannedCode: String, withFormat format: ScanFormat?, withTemplate template: String? = nil) {
        
        self.barcodeDetector.pauseScanning()
        self.processingDelegate?.processing = true
        
        self.lookupCode(scannedCode, withFormat: format, withTemplate: template) { scannedResult in
            
            self.processingDelegate?.processing = false
            let scannedProduct: ScannedProduct
            switch scannedResult {
            case .failure(let error):
                self.logger.debug("got error for code: \(scannedCode) -> \(error.localizedDescription)")
                self.showScanLookupError(error, forCode: scannedCode)
                return
                
            case .product(let product):
                self.logger.debug("got product: \(product.product.name)")
                scannedProduct = product
                
            case .coupon(let coupon, let scannedCode):
                self.logger.debug("got coupon: \(coupon.name)")
                self.shoppingCart.addCoupon(coupon, scannedCode: scannedCode)
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
                let msg = Asset.localizedString(forKey: "Snabble.Scanner.couponAdded", arguments: coupon.name)
                self.processingDelegate?.scanMessage = ScanMessage(msg)
                return
                
            case .voucher(let voucher):
                self.logger.debug("got voucher: \(voucher.scannedCode)")
                self.shoppingCart.addVoucher(voucher)
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
                self.tapticFeedback.notificationOccurred(.success)
                return
            }
            
            let product = scannedProduct.product
            let embeddedData = scannedProduct.embeddedData
            
            // check for sale stop / notForSale
            if self.isSaleProhibited(of: product, scannedCode: scannedCode) {
                return
            }
            
            // handle scanning the shelf code of a pre-weighed product (no data or 0 encoded in the EAN)
            if product.type == .preWeighed && (embeddedData == nil || embeddedData == 0) {
                let msg = Asset.localizedString(forKey: "Snabble.Scanner.scannedShelfCode")
                self.scannedUnknown(messageText: msg, code: scannedCode)
                return
            }
            
            self.tapticFeedback.notificationOccurred(.success)
            
            self.processingDelegate?.track(.scanProduct(scannedProduct.transmissionCode ?? scannedCode))
            
            let item = ScannedItem(scannedProduct: scannedProduct, code: scannedCode, type: product.type)
            self.processingDelegate?.scannedItem = item
            self.logger.debug("scannedItem: \(item)")
            
            if !product.bundles.isEmpty || scannedProduct.priceOverride == nil {
                self.collectBundles(for: item)
            }
        }
    }
    
    private func showScanLookupError(_ error: ProductLookupError, forCode scannedCode: String) {
        let errorMsg: String
        switch error {
        case .notFound: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.unknownBarcode")
        case .networkError: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.networkError")
        case .serverError: errorMsg = Asset.localizedString(forKey: "Snabble.Scanner.serverError")
        }
        
        self.scannedUnknown(messageText: errorMsg, code: scannedCode)
    }
    
    private func isSaleProhibited(of product: Product, scannedCode: String) -> Bool {
        // check for sale stop
        if product.saleStop {
            self.showSaleStop()
            return true
        }
        
        // check for not-for-sale
        if product.notForSale {
            self.showNotForSale(for: product, withCode: scannedCode)
            return true
        }
        
        return false
    }
    
    private func showSaleStop() {
        self.tapticFeedback.notificationOccurred(.error)
        self.processingDelegate?.errorMessage = Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.scan")
    }
    
    private func showNotForSale(for product: Product, withCode scannedCode: String) {
        self.tapticFeedback.notificationOccurred(.error)
        if let message = self.scannerDelegate?.scanMessage(for: self.project, self.shop, product) {
            self.processingDelegate?.scanMessage = message
        } else {
            self.scannedUnknown(messageText: Asset.localizedString(forKey: "Snabble.NotForSale.ErrorMsg.scan"), code: scannedCode)
        }
    }
    
    private func collectBundles(for item: ScannedItem) {
        let product = item.scannedProduct.product
        
        var bundles: [ScannedItem] = []
        
        for bundle in product.bundles {
            let bundleCode = bundle.codes.first?.code
            let transmissionCode = bundle.codes.first?.transmissionCode ?? bundleCode
            let lookupCode = transmissionCode ?? item.code
            let specifiedQuantity = bundle.codes.first?.specifiedQuantity
            let scannedBundle = ScannedProduct(bundle, lookupCode, transmissionCode,
                                               specifiedQuantity: specifiedQuantity)
            
            if !self.isSaleProhibited(of: scannedBundle.product, scannedCode: item.code) {
                bundles.append(ScannedItem(scannedProduct: scannedBundle, code: transmissionCode ?? item.code, type: item.type))
            }
        }
        self.processingDelegate?.bundles = bundles
    }
    
    private func lookupCode(_ code: String,
                            withFormat format: ScanFormat?,
                            withTemplate template: String?,
                            completion: @escaping (ScannerLookup) -> Void ) {
        // if we were given a template from the barcode entry, use that to lookup the product directly
        if let template = template {
            return self.lookupProduct(for: code, withTemplate: template, priceOverride: nil, completion: completion)
        }
        
        // check override codes first
        let project = self.project
        if let match = CodeMatcher.matchOverride(code, project.priceOverrideCodes, project.id) {
            return self.productForOverrideCode(for: match, completion: completion)
        }
        
        // then, check our regular templates
        let matches = CodeMatcher.match(code, project.id)
        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }
        
        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))
        
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                guard let parseResult = matches.first(where: { $0.template.id == lookupResult.templateId }) else {
                    completion(.failure(.notFound))
                    return
                }
                
                let scannedCode = lookupResult.transmissionCode ?? code
                var newResult = ScannedProduct(lookupResult.product,
                                               parseResult.lookupCode,
                                               scannedCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: parseResult.embeddedData,
                                               encodingUnit: lookupResult.encodingUnit,
                                               referencePriceOverride: parseResult.referencePrice,
                                               specifiedQuantity: lookupResult.specifiedQuantity)
                
                if let decimalData = parseResult.embeddedDecimal {
                    var encodingUnit = lookupResult.product.encodingUnit
                    var embeddedData: Int?
                    let div = Int(pow(10.0, Double(decimalData.fractionDigits)))
                    if let enc = encodingUnit {
                        switch enc {
                        case .piece:
                            encodingUnit = .piece
                            embeddedData = decimalData.value / div
                        case .kilogram, .meter, .liter, .squareMeter:
                            encodingUnit = enc.fractionalUnit(div)
                            embeddedData = decimalData.value
                        case .gram, .millimeter, .milliliter:
                            embeddedData = decimalData.value
                        default:
                            Log.warn("unspecified conversion for embedded data: \(decimalData.value) \(enc)")
                        }
                    }
                    
                    newResult = ScannedProduct(lookupResult.product, parseResult.lookupCode, scannedCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: embeddedData,
                                               encodingUnit: encodingUnit,
                                               referencePriceOverride: newResult.referencePriceOverride,
                                               specifiedQuantity: lookupResult.specifiedQuantity)
                }
                
                completion(.product(newResult))
            case .failure(let error):
                if error == .notFound {
                    if let gs1 = self.checkValidGS1(for: code) {
                        return self.productForGS1(gs1: gs1, originalCode: code, completion: completion)
                    }
                    
                    // is this a valid coupon?
                    if let coupon = self.checkValidCoupon(for: code) {
                        return completion(.coupon(coupon, code))
                    }
                    
                    if let voucher = self.checkValidVoucher(for: code) {
                        return completion(.voucher(voucher))
                    }
                    return completion(.failure(.notFound))
                } else {
                    let event = AppEvent(scannedCode: code, codes: codes, project: project)
                    event.post()
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func checkValidVoucher(for scannedCode: String) -> Voucher? {
        let project = self.project
        let vouchers = project.depositReturnVouchers
        
        for voucher in vouchers {
            for template in voucher.templates {
                let result = CodeMatcher.match(scannedCode, project.id)
                if result.first(where: { $0.template.id == template.id }) != nil {
                    return Voucher(id: UUID().uuidString, itemID: voucher.id, type: .depositReturn, scannedCode: scannedCode)
                }
            }
        }
        
        return nil
    }
    
    private func checkValidCoupon(for scannedCode: String) -> Coupon? {
        let project = self.project
        let validCoupons = project.printedCoupons
        
        for coupon in validCoupons {
            for code in coupon.codes ?? [] {
                let result = CodeMatcher.match(scannedCode, project.id)
                if result.first(where: { $0.template.id == code.template && $0.lookupCode == code.code }) != nil {
                    return coupon
                }
            }
        }
        
        return nil
    }
    
    private func checkValidGS1(for code: String) -> GS1Code? {
        let gs1 = GS1Code(code)
        if gs1.gtin != nil {
            return gs1
        }
        return nil
    }
    
    private func productForGS1(gs1: GS1Code,
                               originalCode: String,
                               completion: @escaping (ScannerLookup) -> Void ) {
        guard let gtin = gs1.gtin else {
            return completion(.failure(.notFound))
        }
        
        let codes = [(gtin, CodeTemplate.defaultName)]
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let priceDigits = self.project.decimalDigits
                let roundingMode = self.project.roundingMode
                let (embeddedData, encodingUnit) = gs1.getEmbeddedData(for: lookupResult.encodingUnit, priceDigits, roundingMode)
                let result = ScannedProduct(lookupResult.product,
                                            gtin,
                                            originalCode,
                                            templateId: CodeTemplate.defaultName,
                                            transmissionTemplateId: nil,
                                            embeddedData: embeddedData,
                                            encodingUnit: encodingUnit,
                                            referencePriceOverride: nil,
                                            specifiedQuantity: lookupResult.specifiedQuantity)
                completion(.product(result))
            case .failure(let error):
                let event = AppEvent(scannedCode: originalCode, codes: codes, project: self.project)
                event.post()
                completion(.failure(error))
            }
        }
    }
    
    private func productForOverrideCode(for match: OverrideLookup, completion: @escaping (ScannerLookup) -> Void ) {
        let code = match.lookupCode
        
        if let template = match.lookupTemplate {
            return self.lookupProduct(for: code, withTemplate: template, priceOverride: match.embeddedData, completion: completion)
        }
        
        let matches = CodeMatcher.match(code, self.project.id)
        
        guard !matches.isEmpty else {
            return completion(.failure(.notFound))
        }
        
        let lookupCodes = matches.map { $0.lookupCode }
        let templates = matches.map { $0.template.id }
        let codes = Array(zip(lookupCodes, templates))
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let newResult = ScannedProduct(lookupResult.product, code, match.transmissionCode,
                                               templateId: lookupResult.templateId,
                                               transmissionTemplateId: lookupResult.transmissionTemplateId,
                                               embeddedData: nil,
                                               encodingUnit: .price,
                                               specifiedQuantity: lookupResult.specifiedQuantity,
                                               priceOverride: match.embeddedData)
                completion(.product(newResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func lookupProduct(for code: String, withTemplate template: String, priceOverride: Int?, completion: @escaping (ScannerLookup) -> Void ) {
        let codes = [(code, template)]
        self.productProvider.productBy(codes: codes, shopId: self.shop.id) { result in
            switch result {
            case .success(let lookupResult):
                let transmissionCode = lookupResult.product.codes[0].transmissionCode
                let scannedProduct: ScannedProduct
                if let priceOverride = priceOverride {
                    scannedProduct = ScannedProduct(lookupResult.product, code, transmissionCode,
                                                    templateId: template,
                                                    transmissionTemplateId: lookupResult.transmissionTemplateId,
                                                    embeddedData: nil,
                                                    encodingUnit: .price,
                                                    referencePriceOverride: nil,
                                                    specifiedQuantity: lookupResult.specifiedQuantity,
                                                    priceOverride: priceOverride)
                } else {
                    scannedProduct = ScannedProduct(lookupResult.product, code, transmissionCode,
                                                    templateId: template,
                                                    transmissionTemplateId: lookupResult.transmissionTemplateId,
                                                    specifiedQuantity: lookupResult.specifiedQuantity)
                }
                completion(.product(scannedProduct))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
