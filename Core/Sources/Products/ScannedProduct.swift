//
//  ScannedProduct.swift
//  
//
//  Created by Uwe Tilemann on 04.11.22.
//

import Foundation

/// the return type from `productByScannableCodes`
public struct ScannedProduct: Sendable {
    /// contains the product found
    public let product: Product
    /// can be used to override the code that gets sent to the backend, e.g. when an EAN-8 is scanned, but the backend requires EAN-13s
    public let transmissionCode: String?
    /// the template that was used to match this code, if any
    public let templateId: String?
    /// the template we should use to generate the QR code, if not same as `templateId`
    public let transmissionTemplateId: String?
    /// the embedded data from the scanned code (from the {embed} template component), if any
    public let embeddedData: Int?
    /// the units of the embedded data, if any
    public let encodingUnit: Units?
    /// optional override for the product's price per `referenceUnit`
    public let referencePriceOverride: Int?
    /// optional override for the product's price
    public let priceOverride: Int?
    /// the lookup code we used to find the product in the database
    public let lookupCode: String
    /// the specified quantity
    public let specifiedQuantity: Int?

    public init(_ product: Product,
                _ lookupCode: String,
                _ transmissionCode: String?,
                templateId: String? = nil,
                transmissionTemplateId: String? = nil,
                embeddedData: Int? = nil,
                encodingUnit: Units? = nil,
                referencePriceOverride: Int? = nil,
                specifiedQuantity: Int?,
                priceOverride: Int? = nil) {
        self.product = product
        self.lookupCode = lookupCode
        self.transmissionCode = transmissionCode
        self.templateId = templateId
        self.transmissionTemplateId = transmissionTemplateId
        self.embeddedData = embeddedData
        self.encodingUnit = encodingUnit ?? product.encodingUnit
        self.referencePriceOverride = referencePriceOverride
        self.specifiedQuantity = specifiedQuantity
        self.priceOverride = priceOverride
    }
}
