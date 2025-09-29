//
//  PaymentMethodDetails.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess

public enum PaymentMethodError: Error {
    case unknownMethodError(String)
    case invalidCertificate
    case encryptionError
}
///
/// Checklist for adding a new payment method:
/// * create a new struct eg. `InvoiceByLoginData` to store the payment data by implementing the `EncryptedPaymentData` protocol.
/// * extend the `AcceptedOriginType` to identify the new paymentMethod from a backend response `case contactPersonCredentials`
/// 
/// * add a new case to `public enum PaymentMethodUserData` eg. `invoiceByLogin(InvoiceByLoginData)`
/// * add a new `CodingKey` case eg. `invoiceByLogin`
/// * implement all required switch statements:
/// * `public var data: EncryptedPaymentData` eg. `case .invoiceByLogin(let data): return data`
/// * `init(from decoder: Decoder)`
/// * `encode(to encoder: Encoder)`
///  * Implement an init function fro struct `PaymentMethodDetail` like eg. `init(_ invoiceByLoginData: InvoiceByLoginData)`
///  * extent the `public var rawMethod: RawPaymentMethod` to return a valid value `case .invoiceByLoginData: return .externalBilling`
///  * and the `public var projectId: Identifier<Project>?`
///  * check `public var imageName: String` of the extension to `PaymentMethodDetail` if you need a separate imageName for the new payment menthod

public enum PaymentMethodUserData: Codable, Equatable {
    case sepa(SepaData)
    case teleCashCreditCard(TeleCashCreditCardData)
    case tegutEmployeeCard(TegutEmployeeData)
    case giropayAuthorization(GiropayData)
    case datatransAlias(DatatransData)
    case datatransCardAlias(DatatransCreditCardData)
    case payoneCreditCard(PayoneCreditCardData)
    case payoneSepa(PayoneSepaData)
    case invoiceByLogin(InvoiceByLoginData)

    public enum CodingKeys: String, CodingKey {
        case sepa
        case teleCashCreditCard
        case tegutEmployeeCard
        case giropayAuthorization = "paydirektAuthorization"
        case datatransAlias, datatransCardAlias
        case payoneCreditCard
        case payoneSepa
        case leinweberCustomerNumber
        case invoiceByLogin
        
        // old and bad name - only used in the migration code below
        case creditcard
    }

    public var data: EncryptedPaymentData {
        switch self {
        case .sepa(let data): return data
        case .teleCashCreditCard(let data): return data
        case .tegutEmployeeCard(let data): return data
        case .giropayAuthorization(let data): return data
        case .datatransAlias(let data): return data
        case .datatransCardAlias(let data): return data
        case .payoneCreditCard(let data): return data
        case .payoneSepa(let data): return data
        case .invoiceByLogin(let data): return data
        }
    }

    public var additionalData: [String: String] {
        switch self {
        case .giropayAuthorization(let data): return data.additionalData
        case .teleCashCreditCard(let data): return data.additionalData
        default: return [:]
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let sepa = try container.decodeIfPresent(SepaData.self, forKey: .sepa) {
            self = .sepa(sepa)
        } else if let creditcard = try container.decodeIfPresent(TeleCashCreditCardData.self, forKey: .creditcard) {
            self = .teleCashCreditCard(creditcard)
        } else if let creditcard = try container.decodeIfPresent(TeleCashCreditCardData.self, forKey: .teleCashCreditCard) {
            self = .teleCashCreditCard(creditcard)
        } else if let tegutData = try container.decodeIfPresent(TegutEmployeeData.self, forKey: .tegutEmployeeCard) {
            self = .tegutEmployeeCard(tegutData)
        } else if let giropayData = try container.decodeIfPresent(GiropayData.self, forKey: .giropayAuthorization) {
            self = .giropayAuthorization(giropayData)
        } else if let datatransData = try container.decodeIfPresent(DatatransData.self, forKey: .datatransAlias) {
            self = .datatransAlias(datatransData)
        } else if let datatransCardData = try container.decodeIfPresent(DatatransCreditCardData.self, forKey: .datatransCardAlias) {
            self = .datatransCardAlias(datatransCardData)
        } else if let payoneData = try container.decodeIfPresent(PayoneCreditCardData.self, forKey: .payoneCreditCard) {
            self = .payoneCreditCard(payoneData)
        } else if let payoneSepa = try container.decodeIfPresent(PayoneSepaData.self, forKey: .payoneSepa) {
            self = .payoneSepa(payoneSepa)
       } else if let invoiceData = try container.decodeIfPresent(InvoiceByLoginData.self, forKey: .invoiceByLogin) {
            self = .invoiceByLogin(invoiceData)
        } else {
            throw PaymentMethodError.unknownMethodError("unknown payment method")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sepa(let data): try container.encode(data, forKey: .sepa)
        case .teleCashCreditCard(let data): try container.encode(data, forKey: .teleCashCreditCard)
        case .tegutEmployeeCard(let data): try container.encode(data, forKey: .tegutEmployeeCard)
        case .giropayAuthorization(let data): try container.encode(data, forKey: .giropayAuthorization)
        case .datatransAlias(let data): try container.encode(data, forKey: .datatransAlias)
        case .datatransCardAlias(let data): try container.encode(data, forKey: .datatransCardAlias)
        case .payoneCreditCard(let data): try container.encode(data, forKey: .payoneCreditCard)
        case .payoneSepa(let data): try container.encode(data, forKey: .payoneSepa)
        case .invoiceByLogin(let data): try container.encode(data, forKey: .invoiceByLogin)
        }
    }
}

public extension PaymentMethod {
    static func make(_ rawMethod: RawPaymentMethod, _ detail: PaymentMethodDetail?) -> PaymentMethod? {
        if let detail = detail, detail.rawMethod != rawMethod {
            Log.error("payment method mismatch: \(detail.rawMethod) != \(rawMethod)")
            assert(detail.rawMethod == rawMethod)
            return nil
        }

        switch rawMethod {
        case .qrCodePOS: return .qrCodePOS
        case .qrCodeOffline: return .qrCodeOffline
        case .gatekeeperTerminal: return .gatekeeperTerminal
        case .customerCardPOS: return .customerCardPOS
        case .applePay: return .applePay
        case .deDirectDebit:
            if let data = detail?.data {
                return .deDirectDebit(data)
            }
        case .creditCardVisa:
            if let data = detail?.data {
                return .visa(data)
            }
        case .creditCardMastercard:
            if let data = detail?.data {
                return .mastercard(data)
            }
        case .creditCardAmericanExpress:
            if let data = detail?.data {
                return .americanExpress(data)
            }
        case .externalBilling:
            if let data = detail?.data {
                return .externalBilling(data)
            }
        case .giropayOneKlick:
            if let data = detail?.data {
                return .giropayOneKlick(data)
            }
        case .twint:
            if let data = detail?.data {
                return .twint(data)
            }
        case .postFinanceCard:
            if let data = detail?.data {
                return .postFinanceCard(data)
            }
        }

        return nil
    }
}

public struct PaymentMethodDetail: Equatable {
    public let id: UUID
    public let methodData: PaymentMethodUserData

    public init(_ sepaData: SepaData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.sepa(sepaData)
    }

    public init(_ creditcardData: TeleCashCreditCardData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.teleCashCreditCard(creditcardData)
    }

    public init(_ tegutData: TegutEmployeeData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.tegutEmployeeCard(tegutData)
    }

    public init(_ paydirektData: GiropayData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.giropayAuthorization(paydirektData)
    }

    public init(_ datatransData: DatatransData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.datatransAlias(datatransData)
    }

    public init(_ datatransCardData: DatatransCreditCardData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.datatransCardAlias(datatransCardData)
    }

    public init(_ payoneData: PayoneCreditCardData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.payoneCreditCard(payoneData)
    }
    public init(_ payoneSepaData: PayoneSepaData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.payoneSepa(payoneSepaData)
    }

    public init(_ invoiceByLoginData: InvoiceByLoginData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.invoiceByLogin(invoiceByLoginData)
    }

    public var displayName: String {
        return self.methodData.data.displayName
    }

    public var encryptedData: String {
        return self.methodData.data.encryptedPaymentData
    }

    public var additionalData: [String: String] {
        return self.methodData.additionalData
    }

    public var serial: String {
        return self.methodData.data.serial
    }

    public var data: PaymentMethodData {
        return PaymentMethodData(self.displayName, self.encryptedData, self.originType, self.additionalData)
    }

    public var isExpired: Bool {
        return self.methodData.data.isExpired
    }

    public var rawMethod: RawPaymentMethod {
        switch self.methodData {
        case .sepa, .payoneSepa: return .deDirectDebit
        case .tegutEmployeeCard, .invoiceByLogin:
            return .externalBilling
        case .giropayAuthorization:
            return .giropayOneKlick
        case .datatransAlias(let datatransData):
            switch datatransData.method {
            case .twint: return .twint
            case .postFinanceCard: return .postFinanceCard
            }
        case .teleCashCreditCard(let ccData as BrandedCreditCard),
                .datatransCardAlias(let ccData as BrandedCreditCard),
                .payoneCreditCard(let ccData as BrandedCreditCard):
            switch ccData.brand {
            case .mastercard: return .creditCardMastercard
            case .visa: return .creditCardVisa
            case .amex: return .creditCardAmericanExpress
            }
        }
    }

    public var originType: AcceptedOriginType {
        return self.methodData.data.originType
    }

    public var projectId: Identifier<Project>? {
        switch self.methodData {
        case .teleCashCreditCard(let creditCardData):
            return creditCardData.projectId
        case .datatransAlias(let datatransData):
            return datatransData.projectId
        case .datatransCardAlias(let datatransData):
            return datatransData.projectId
        case .payoneCreditCard(let payoneData):
            return payoneData.projectId
        case .payoneSepa(let payoneSepaData):
            return payoneSepaData.projectId
        case .invoiceByLogin(let invoiceData):
            return invoiceData.projectId
        case .sepa, .tegutEmployeeCard, .giropayAuthorization:
            return nil
        }
    }
}

extension PaymentMethodDetail {
    public var imageName: String {
        switch self.methodData {
        case .tegutEmployeeCard:
            return "payment-tegut"
        case .invoiceByLogin:
            return "payment-invoice"
            
        default:
            return self.rawMethod.imageName
        }
    }
}

extension RawPaymentMethod {
    public var imageName: String {
        switch self {
        case .deDirectDebit:
            return "payment-sepa"
        case .creditCardVisa:
            return "payment-visa"
        case .creditCardMastercard:
            return "payment-mastercard"
        case .creditCardAmericanExpress:
            return "payment-amex"
        case .gatekeeperTerminal:
            return "payment-sco"
        case .giropayOneKlick:
            return "payment-giropay"
        case .applePay:
            return "payment-apple-pay"
        case .twint:
            return "payment-twint"
        case .postFinanceCard:
            return "payment-postfinance"
        case .externalBilling:
            return "payment-invoice"
        case .qrCodePOS, .qrCodeOffline, .customerCardPOS:
            return "payment-pos"
        }
    }
}

extension PaymentMethodDetail: Codable {
    enum CodingKeys: String, CodingKey {
        case id, methodData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.methodData = try container.decode(PaymentMethodUserData.self, forKey: .methodData)
    }
}

extension Notification.Name {
    /// new payment method.
    /// `userInfo["detail"]` contains a `PaymentMethodDetail` instance
    public static let snabblePaymentMethodAdded = Notification.Name("snabblePaymentMethodAdded")
    public static let snabblePaymentMethodDeleted = Notification.Name("snabblePaymentMethodDeleted")
}

struct PaymentMethodDetailStorage {
    enum SettingsKeys {
        static let paymentMethods = "paymentMethods"
    }

    private var keychain = Keychain(service: "io.snabble.app").accessibility(.whenPasscodeSetThisDeviceOnly)
    private var key: String {
        SettingsKeys.paymentMethods + "." + Snabble.shared.config.environment.name + "." + Snabble.shared.config.appId
    }

    func read() -> [PaymentMethodDetail] {
        if let methodsJSON = self.keychain[self.key] {
            do {
                let data = methodsJSON.data(using: .utf8)!
                let methods = try JSONDecoder().decode([PaymentMethodDetail].self, from: data)
                return methods
            } catch {
                Log.error("\(error)")
            }
        }
        return []
    }

    func save(_ details: [PaymentMethodDetail]) {
        do {
            let stored = self.read()

            func added() -> [PaymentMethodDetail] {
                var added = [PaymentMethodDetail]()
                
                for detail in details where !stored.contains(detail) {
                    added.append(detail)
                }
                return added
            }
            func removed() -> [PaymentMethodDetail] {
                var removed = [PaymentMethodDetail]()
                
                for detail in stored where !details.contains(detail) {
                    removed.append(detail)
                }
                return removed
            }

            let added = added()
            let removed = removed()

            let data = try JSONEncoder().encode(details)
            self.keychain[self.key] = String(bytes: data, encoding: .utf8)!

            if !added.isEmpty {
                for detail in added {
                    NotificationCenter.default.post(name: .snabblePaymentMethodAdded, object: nil, userInfo: [ "detail": detail ])
                }
            }
            if !removed.isEmpty {
                NotificationCenter.default.post(name: .snabblePaymentMethodDeleted, object: nil)
            }
        } catch {
            Log.error("\(error)")
        }
    }

    func save(_ detail: PaymentMethodDetail) {
        var details = self.read()

        let index = details.firstIndex { $0.id == detail.id }

        if let idx = index {
            details[idx] = detail
        } else {
            details.append(detail)
        }

        self.save(details)

        // if the method was newly added, post a notification
        if index == nil {
            let nc = NotificationCenter.default
            nc.post(name: .snabblePaymentMethodAdded, object: nil, userInfo: [ "detail": detail ])
        }
    }

    func remove(_ detail: PaymentMethodDetail) {
        var details = self.read()
        details.removeAll { $0.id == detail.id }
        self.save(details)

        NotificationCenter.default.post(name: .snabblePaymentMethodDeleted, object: nil)
    }

    func removeAll() {
        let oldKey = SettingsKeys.paymentMethods + Snabble.shared.config.environment.name
        let oldData = self.keychain[oldKey]

        let keys = self.keychain.allKeys()
        for key in keys where key.hasPrefix(SettingsKeys.paymentMethods) {
            try? self.keychain.remove(key)
        }

        if let data = oldData {
            self.keychain[self.key] = data
        }
    }
}

public enum PaymentMethodDetails {
    nonisolated(unsafe) private static let storage = PaymentMethodDetailStorage()

    public static func read() -> [PaymentMethodDetail] {
        return storage.read()
    }

    public static func save(_ details: [PaymentMethodDetail]) {
        storage.save(details)
    }

    public static func save(_ detail: PaymentMethodDetail) {
        storage.save(detail)
    }

    public static func remove(_ detail: PaymentMethodDetail) {
        storage.remove(detail)
    }

    /// This method silently removes all payment methods
    public static func removeAll() {
        storage.removeAll()
    }
    
    /// This method silently removes any payment methods that have expired, most notably credit cards past
    /// their expiration date.
    public static func removeExpired() {
        var details = self.read()
        details.removeAll(where: \.isExpired)
        self.save(details)
    }

    /// This method silently unsupported payment methods.
    ///
    /// - Returns: true when any obsolete payment methods had to be removed
    public static func removeObsoleted() -> Bool {
        var details = self.read()
        let initialCount = details.count
        details.removeAll { detail -> Bool in
            switch detail.methodData {
            case .teleCashCreditCard(let creditcardData):
                return creditcardData.version < TeleCashCreditCardData.TeleCashRequestOrigin.version
            default:
                return false
            }
        }

        self.save(details)
        return initialCount != details.count
    }
}

// extensions for tegut employee cards that can be used as payment methods
extension PaymentMethodDetails {
    public static func addTegutEmployeeCard(_ number: String, _ name: String, _ projectId: Identifier<Project>) {
        guard
            let cert = Snabble.shared.certificates.first,
            let employeeData = TegutEmployeeData(cert.data, number, name, projectId)
        else {
            return
        }

        var details = self.read().filter { $0.originType != .tegutEmployeeID }
        details.append(PaymentMethodDetail(employeeData))
        self.save(details)
    }

    public static func removeTegutEmployeeCard() {
        let details = self.read().filter { $0.originType != .tegutEmployeeID }
        self.save(details)
    }
}
