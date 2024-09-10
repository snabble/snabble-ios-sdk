//
//  Project.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct Company: Decodable {
    public let name: String
    public let city: String
    public let country: String
    public let street: String?
    public let zip: String?
}

public struct ProjectLinks: Decodable {
    public let appdb: Link
    public let appEvents: Link
    public let checkoutInfo: Link
    public let tokens: Link
    public let resolvedProductBySku: Link?
    public let resolvedProductLookUp: Link?
    public let assetsManifest: Link?
    public let entryToken: Link?
    public let shoppingListDB: Link?
    public let customerLoyaltyInfo: Link?
    public let activeShops: Link?
    public let coupons: Link?
    public let news: Link?
    public let teasers: Link?

    public static let empty = ProjectLinks()

    private init() {
        self.appdb = Link.empty
        self.appEvents = Link.empty
        self.checkoutInfo = Link.empty
        self.tokens = Link.empty

        self.resolvedProductBySku = nil
        self.resolvedProductLookUp = nil
        self.assetsManifest = nil
        self.entryToken = nil
        self.shoppingListDB = nil
        self.customerLoyaltyInfo = nil
        self.activeShops = nil
        self.coupons = nil
        self.news = nil
        self.teasers = nil
    }

    init(appdb: Link, appEvents: Link, checkoutInfo: Link, tokens: Link, resolvedProductBySku: Link, resolvedProductLookUp: Link) {
        self.appdb = appdb
        self.appEvents = appEvents
        self.checkoutInfo = checkoutInfo
        self.tokens = tokens
        self.resolvedProductBySku = resolvedProductBySku
        self.resolvedProductLookUp = resolvedProductLookUp

        self.assetsManifest = nil
        self.entryToken = nil
        self.shoppingListDB = nil
        self.customerLoyaltyInfo = nil
        self.activeShops = nil
        self.coupons = nil
        self.news = nil
        self.teasers = nil
    }
}

public enum RoundingMode: String, Codable, UnknownCaseRepresentable {
    /// always round up
    case up
    /// always round down
    case down
    /// round to the closest possible value; when caught halfway between two positive numbers, round up; when caught between two negative numbers, round down.
    /// (ie use `NSDecimalNumber.RoundingMode.plain`)
    case commercial

    /// get the appropriate `NSDecimalNumber.RoundingMode`
    var mode: NSDecimalNumber.RoundingMode {
        switch self {
        case .up: return .up
        case .down: return .down
        case .commercial: return .plain
        }
    }

    public static let unknownCase = RoundingMode.up
}

public enum QRCodeFormat: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case simple
    // swiftlint:disable:next identifier_name
    case csv_globus // simple header, deprecated
    case csv        // new format with "x of y" header info
    case ikea

    var repeatCodes: Bool {
        switch self {
        case .csv, .csv_globus: return false
        case .ikea, .simple: return true
        case .unknown: return true
        }
    }

    public static let unknownCase = QRCodeFormat.unknown
}

public struct QRCodeConfig: Decodable {
    let format: QRCodeFormat

    let prefix: String
    let separator: String
    let suffix: String
    let maxCodes: Int

    // optional EAN codes used when splitting into multiple QR codes

    // last code of the last block
    let finalCode: String?

    // last code of the last block if there are any manual discounts
    // NB: when both `finalCode` and `manualDiscountFinalCode` are defined and there are any manual discounts,
    // both are appended to the QR code
    let manualDiscountFinalCode: String?

    // marker code to indicate "more QR codes"
    let nextCode: String?

    // marker code to indicate "more QR codes" + age check required
    let nextCodeWithCheck: String?

    // when maxCodes is not sufficiently precise, maxChars imposes a string length limit
    let maxChars: Int?

    // the maximum number of characters/bytes that can be encoded in one QR code
    static let qrCodeMax = 2953

    var effectiveMaxCodes: Int {
        switch (finalCode, manualDiscountFinalCode) {
        case (.some, .some): return maxCodes - 2
        case (.some, .none), (.none, .some): return maxCodes - 1
        case (.none, .none): ()
        }

        if nextCode != nil || self.nextCodeWithCheck != nil {
            return maxCodes - 1
        }

        return maxCodes
    }

    enum CodingKeys: String, CodingKey {
        case format
        case prefix, separator, suffix, maxCodes, maxChars
        case finalCode, nextCode, nextCodeWithCheck
        case manualDiscountFinalCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.format = try container.decode(QRCodeFormat.self, forKey: .format)

        self.prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        self.separator = try container.decodeIfPresent(String.self, forKey: .separator) ?? "\n"
        self.suffix = try container.decodeIfPresent(String.self, forKey: .suffix) ?? ""
        self.maxCodes = try container.decodeIfPresent(Int.self, forKey: .maxCodes) ?? 100

        if let maxChars = try container.decodeIfPresent(Int.self, forKey: .maxChars) {
            self.maxChars = min(maxChars, Self.qrCodeMax)
        } else {
            self.maxChars = nil
        }

        self.finalCode = try container.decodeIfPresent(String.self, forKey: .finalCode)
        self.manualDiscountFinalCode = try container.decodeIfPresent(String.self, forKey: .manualDiscountFinalCode)
        self.nextCode = try container.decodeIfPresent(String.self, forKey: .nextCode)
        self.nextCodeWithCheck = try container.decodeIfPresent(String.self, forKey: .nextCodeWithCheck)
    }

    init(format: QRCodeFormat,
         prefix: String = "",
         separator: String = "\n",
         suffix: String = "",
         maxCodes: Int = 100,
         maxChars: Int? = nil,
         finalCode: String? = nil,
         manualDiscountFinalCode: String? = nil,
         nextCode: String? = nil,
         nextCodeWithCheck: String? = nil
    ) {
        self.format = format
        self.prefix = prefix
        self.separator = separator
        self.suffix = suffix
        self.maxCodes = maxCodes
        if let maxChars = maxChars {
            self.maxChars = min(maxChars, Self.qrCodeMax)
        } else {
            self.maxChars = nil
        }
        self.finalCode = finalCode
        self.manualDiscountFinalCode = manualDiscountFinalCode
        self.nextCode = nextCode
        self.nextCodeWithCheck = nextCodeWithCheck
    }
}

public enum ScanFormat: String, Codable, CaseIterable, UnknownCaseRepresentable {
    case unknown

    // 1d codes
    case ean13      // includes UPC-A
    case ean8
    case code128
    case itf14
    case code39

    // 2d codes
    case qr
    case dataMatrix = "datamatrix"
    case pdf417

    public static let unknownCase = Self.unknown
}

public enum BarcodeDetectorType: String, Decodable, UnknownCaseRepresentable {
    case `default`
    case cortex

    public static let unknownCase = BarcodeDetectorType.default
}

public struct CustomerCardInfo: Decodable {
    public let required: String?
    public let accepted: [String]?

    init(_ required: String? = nil, _ accepted: [String]? = nil) {
        self.required = required
        self.accepted = accepted
    }
}

public struct TemplateDefinition: Decodable {
    public let id: String
    public let template: String

    static func arrayFrom(_ templates: [String: String]?) -> [TemplateDefinition] {
        guard let templates = templates else {
            return []
        }

        let result: [TemplateDefinition] = templates.reduce(into: []) { result, entry in
            result.append(TemplateDefinition(id: entry.key, template: entry.value))
        }
        return result
    }
}

public struct PriceOverrideCode: Decodable {
    public let id: String
    public let template: String
    public let lookupTemplate: String?
    public let transmissionTemplate: String?
    public let transmissionCode: String?
}

public struct CheckoutLimits: Decodable {
    public let notAllMethodsAvailable: Int?
    public let checkoutNotAvailable: Int?
}

public struct ProjectMessages: Decodable {
    public let sepaMandate: String?
    public let sepaMandateShort: String?
    public let companyNotice: String?
}

public struct CustomizationConfig: Decodable {
    public let colorHexPrimaryLight: String?
    public let colorHexOnPrimaryLight: String?
    public let colorHexSecondaryLight: String?
    public let colorHexOnSecondaryLight: String?
    
    public let colorHexPrimaryDark: String?
    public let colorHexOnPrimaryDark: String?
    public let colorHexSecondaryDark: String?
    public let colorHexOnSecondaryDark: String?
    
    public let landingPage: String?

    enum CodingKeys: String, CodingKey {
        case colorHexPrimaryLight = "colorPrimary_light"
        case colorHexOnPrimaryLight = "colorOnPrimary_light"
        case colorHexSecondaryLight = "colorSecondary_light"
        case colorHexOnSecondaryLight = "colorOnSecondary_light"
        
        case colorHexPrimaryDark = "colorPrimary_dark"
        case colorHexOnPrimaryDark = "colorOnPrimary_dark"
        case colorHexSecondaryDark = "colorSecondary_dark"
        case colorHexOnSecondaryDark = "colorOnSecondary_dark"

        case landingPage = "landingPageImageURL"
    }
}

public struct Project: Decodable, Identifiable {
    public let id: Identifier<Project>
    public let name: String
    public let links: ProjectLinks
    public let rawLinks: [String: Link]

    public let currency: String
    public let decimalDigits: Int
    public let locale: String
    public let roundingMode: RoundingMode
    public let currencySymbol: String   // not part of JSON, derived from the locale

    // config for embedded QR codes
    public let qrCodeConfig: QRCodeConfig?
    public let customizationConfig: CustomizationConfig?

    public let scanFormats: [ScanFormat]
    public let barcodeDetector: BarcodeDetectorType
    public let expectedBarcodeWidth: Int? // if specified, width of a "standard" barcode in mm

    public let customerCards: CustomerCardInfo?

    public let codeTemplates: [TemplateDefinition]
    public let searchableTemplates: [String]?

    public let priceOverrideCodes: [PriceOverrideCode]?

    public let checkoutLimits: CheckoutLimits?

    public let messages: ProjectMessages?

    public let paymentMethodDescriptors: [PaymentMethodDescriptor]
    public var paymentMethods: [RawPaymentMethod] {
        paymentMethodDescriptors.map { $0.id }
    }
    public var availablePaymentMethods: [RawPaymentMethod] {
        paymentMethods.filter { $0.isAvailable }
    }

    public let displayNetPrice: Bool

    public let company: Company?
    public let brandId: Identifier<Brand>?

    // these properties may be updated after the original metadata document has been loaded
    private struct UpdateableProperties {
        var shops = [Shop]()
        var manualCoupons = [Coupon]()
        var printedCoupons = [Coupon]()
        var digitalCoupons = [Coupon]()
    }
    private var updateable: UpdateableProperties
    private let updateLock = ReadWriteLock()

    public var shops: [Shop] { updateLock.reading { updateable.shops } }
    public var manualCoupons: [Coupon] { updateLock.reading { updateable.manualCoupons } }
    public var printedCoupons: [Coupon] { updateLock.reading { updateable.printedCoupons } }
    public var digitalCoupons: [Coupon] { updateLock.reading { updateable.digitalCoupons } }

    enum CodingKeys: String, CodingKey {
        case id, name, links
        case currency, decimalDigits, locale, roundingMode
        case qrCodeConfig = "qrCodeOffline"
        case customizationConfig = "appCustomizationConfig"
        case shops, scanFormats, barcodeDetector, expectedBarcodeWidth
        case customerCards, codeTemplates, searchableTemplates, priceOverrideCodes, checkoutLimits
        case messages = "texts"
        case paymentMethodDescriptors
        case displayNetPrice
        case company
        case brandId = "brandID"
        case coupons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Identifier<Project>.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.links = try container.decode(ProjectLinks.self, forKey: .links)
        self.rawLinks = try container.decode([String: Link].self, forKey: .links)

        self.currency = try container.decode(.currency)
        self.decimalDigits = try container.decode(.decimalDigits)
        self.locale = try container.decode(.locale)
        self.roundingMode = try container.decode(.roundingMode)

        self.qrCodeConfig = try container.decodeIfPresent(.qrCodeConfig)
        self.customizationConfig = try container.decodeIfPresent(CustomizationConfig.self, forKey: .customizationConfig)

        self.currencySymbol = Self.currencySymbol(for: self.currency, locale: self.locale)

        let defaultFormats = [ ScanFormat.ean8.rawValue, ScanFormat.ean13.rawValue, ScanFormat.code128.rawValue ]
        let formats = (try container.decodeIfPresent([String].self, forKey: .scanFormats)) ?? defaultFormats
        self.scanFormats = formats.compactMap { ScanFormat(rawValue: $0) }
        let detector = try container.decodeIfPresent(String.self, forKey: .barcodeDetector)
        self.barcodeDetector = BarcodeDetectorType(rawValue: detector ?? "")
        self.expectedBarcodeWidth = try container.decodeIfPresent(Int.self, forKey: .expectedBarcodeWidth)
        self.customerCards = try container.decodeIfPresent(CustomerCardInfo.self, forKey: .customerCards)
        let templates = try container.decodeIfPresent([String: String].self, forKey: .codeTemplates)
        self.codeTemplates = TemplateDefinition.arrayFrom(templates)
        self.searchableTemplates = try container.decodeIfPresent([String].self, forKey: .searchableTemplates)
        self.priceOverrideCodes = try container.decodeIfPresent([PriceOverrideCode].self, forKey: .priceOverrideCodes)
        self.checkoutLimits = try container.decodeIfPresent(CheckoutLimits.self, forKey: .checkoutLimits)
        self.messages = try container.decodeIfPresent(ProjectMessages.self, forKey: .messages)

        let descriptors = try container.decodeIfPresent([FailableDecodable<PaymentMethodDescriptor>].self, forKey: .paymentMethodDescriptors)
        self.paymentMethodDescriptors = descriptors?.compactMap { $0.value } ?? []

        self.displayNetPrice = try container.decodeIfPresent(Bool.self, forKey: .displayNetPrice) ?? false
        self.company = try container.decodeIfPresent(Company.self, forKey: .company)
        let brandId = try container.decodeIfPresent(String.self, forKey: .brandId) ?? ""
        self.brandId = brandId.isEmpty ? nil : Identifier<Brand>(rawValue: brandId)

        self.updateable = UpdateableProperties()
        updateLock.writing {
            updateable.shops = (try? container.decodeIfPresent([Shop].self, forKey: .shops)) ?? []
        }

        if let coupons = try container.decodeIfPresent([Coupon].self, forKey: .coupons) {
            setCoupons(coupons)
        }
    }

    private init() {
        self.id = Identifier<Project>(rawValue: "none")
        self.name = ""
        self.links = ProjectLinks.empty
        self.rawLinks = [:]
        self.currency = ""
        self.decimalDigits = 0
        self.locale = ""
        self.roundingMode = .up
        self.qrCodeConfig = nil
        self.customizationConfig = nil
        self.currencySymbol = ""
        self.scanFormats = []
        self.barcodeDetector = .default
        self.expectedBarcodeWidth = nil
        self.customerCards = CustomerCardInfo()
        self.codeTemplates = []
        self.searchableTemplates = nil
        self.priceOverrideCodes = nil
        self.checkoutLimits = nil
        self.messages = nil
        self.paymentMethodDescriptors = []
        self.displayNetPrice = false
        self.company = nil
        self.brandId = nil
        self.updateable = UpdateableProperties()
    }

    // only used for unit tests!
    internal init(_ id: String, links: ProjectLinks) {
        self.id = .init(rawValue: id)
        self.name = ""
        self.links = links
        self.rawLinks = [:]
        self.currency = ""
        self.decimalDigits = 0
        self.locale = ""
        self.roundingMode = .up
        self.qrCodeConfig = nil
        self.customizationConfig = nil
        self.currencySymbol = ""
        self.scanFormats = []
        self.barcodeDetector = .default
        self.expectedBarcodeWidth = nil
        self.customerCards = CustomerCardInfo()
        self.codeTemplates = []
        self.searchableTemplates = nil
        self.priceOverrideCodes = nil
        self.checkoutLimits = nil
        self.messages = nil
        self.paymentMethodDescriptors = []
        self.displayNetPrice = false
        self.company = nil
        self.brandId = nil
        self.updateable = UpdateableProperties()
    }

    public static let none = Project()

    // find the currencySymbol for the given currencyCode
    private static func currencySymbol(for currencyCode: String, locale: String) -> String {
        let formatter = NumberFormatter()
        formatter.currencyCode = currencyCode
        formatter.numberStyle = .currency

        // AFAICT there is no API to get the symbol from the code directly, so we need to loop over
        // all available locales to find the first that has a matching code and use its symbol :(
        let allLocales = Locale.availableIdentifiers.lazy.map { Locale(identifier: $0) }
        if let matchingLocale = allLocales.first(where: { $0.currency?.identifier == currencyCode }) {
            formatter.locale = matchingLocale
        } else {
            formatter.locale = Locale(identifier: locale)
        }

        return formatter.currencySymbol
    }

    mutating func setShops(_ shops: [Shop]) {
        updateLock.writing {
            self.updateable.shops = shops
        }
    }

    mutating func setCoupons(_ coupons: [Coupon]) {
        updateLock.writing {
            self.updateable.manualCoupons = coupons.filter { $0.type == .manual }
            self.updateable.printedCoupons = coupons.filter { $0.type == .printed }
            self.updateable.digitalCoupons = coupons.filter { $0.type == .digital }
        }
    }
}

extension Project: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Project: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
