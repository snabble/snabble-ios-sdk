//
//  PaymentMethodDetails.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess

enum PaymentMethodError: Error {
    case unknownMethodError(String)
}

enum PaymentMethodUserData: Codable, Equatable {
    case sepa(SepaData)
    case creditcard(CreditCardData)
    case tegutEmployeeCard(TegutEmployeeData)
    case paydirektAuthorization(PaydirektData)
    case datatransAlias(DatatransData)
    case datatransCardAlias(DatatransCreditCardData)

    enum CodingKeys: String, CodingKey {
        case sepa, creditcard, tegutEmployeeCard, paydirektAuthorization, datatransAlias, datatransCardAlias
    }

    var data: EncryptedPaymentData {
        switch self {
        case .sepa(let data): return data
        case .creditcard(let data): return data
        case .tegutEmployeeCard(let data): return data
        case .paydirektAuthorization(let data): return data
        case .datatransAlias(let data): return data
        case .datatransCardAlias(let data): return data
        }
    }

    var additionalData: [String: String] {
        switch self {
        case .paydirektAuthorization(let data): return data.additionalData
        case .creditcard(let data): return data.additionalData
        default: return [:]
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let sepa = try container.decodeIfPresent(SepaData.self, forKey: .sepa) {
            self = .sepa(sepa)
        } else if let creditcard = try container.decodeIfPresent(CreditCardData.self, forKey: .creditcard) {
            self = .creditcard(creditcard)
        } else if let tegutData = try container.decodeIfPresent(TegutEmployeeData.self, forKey: .tegutEmployeeCard) {
            self = .tegutEmployeeCard(tegutData)
        } else if let paydirektData = try container.decodeIfPresent(PaydirektData.self, forKey: .paydirektAuthorization) {
            self = .paydirektAuthorization(paydirektData)
        } else if let datatransData = try container.decodeIfPresent(DatatransData.self, forKey: .datatransAlias) {
            self = .datatransAlias(datatransData)
        } else if let datatransCardData = try container.decodeIfPresent(DatatransCreditCardData.self, forKey: .datatransCardAlias) {
            self = .datatransCardAlias(datatransCardData)
        } else {
            throw PaymentMethodError.unknownMethodError("unknown payment method")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sepa(let data): try container.encode(data, forKey: .sepa)
        case .creditcard(let data): try container.encode(data, forKey: .creditcard)
        case .tegutEmployeeCard(let data): try container.encode(data, forKey: .tegutEmployeeCard)
        case .paydirektAuthorization(let data): try container.encode(data, forKey: .paydirektAuthorization)
        case .datatransAlias(let data): try container.encode(data, forKey: .datatransAlias)
        case .datatransCardAlias(let data): try container.encode(data, forKey: .datatransCardAlias)
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
        case .paydirektOneKlick:
            if let data = detail?.data {
                return .paydirektOneKlick(data)
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
    let methodData: PaymentMethodUserData

    init(_ sepaData: SepaData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.sepa(sepaData)
    }

    init(_ creditcardData: CreditCardData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.creditcard(creditcardData)
    }

    init(_ tegutData: TegutEmployeeData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.tegutEmployeeCard(tegutData)
    }

    init(_ paydirektData: PaydirektData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.paydirektAuthorization(paydirektData)
    }

    init(_ datatransData: DatatransData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.datatransAlias(datatransData)
    }

    init(_ datatransCardData: DatatransCreditCardData) {
        self.id = UUID()
        self.methodData = PaymentMethodUserData.datatransCardAlias(datatransCardData)
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

    public var data: Snabble.PaymentMethodData {
        return Snabble.PaymentMethodData(self.displayName, self.encryptedData, self.originType, self.additionalData)
    }

    public var isExpired: Bool {
        return self.methodData.data.isExpired
    }

    public var rawMethod: RawPaymentMethod {
        switch self.methodData {
        case .sepa: return .deDirectDebit
        case .creditcard(let creditcardData):
            switch creditcardData.brand {
            case .mastercard: return .creditCardMastercard
            case .visa: return .creditCardVisa
            case .amex: return .creditCardAmericanExpress
            }
        case .tegutEmployeeCard:
            return .externalBilling
        case .paydirektAuthorization:
            return .paydirektOneKlick
        case .datatransAlias(let datatransData):
            switch datatransData.method {
            case .twint: return .twint
            case .postFinanceCard: return .postFinanceCard
            }
        case .datatransCardAlias(let datatransCardData):
            switch datatransCardData.brand {
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
        case .creditcard(let creditCardData):
            return creditCardData.projectId
        case .datatransAlias(let datatransData):
            return datatransData.projectId
        case .datatransCardAlias(let datatransData):
            return datatransData.projectId
        case .sepa, .tegutEmployeeCard, .paydirektAuthorization:
            return nil
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
        return SettingsKeys.paymentMethods + "." + SnabbleAPI.serverName + "." + SnabbleAPI.config.appId
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
            let data = try JSONEncoder().encode(details)
            self.keychain[self.key] = String(bytes: data, encoding: .utf8)!
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
        let oldKey = SettingsKeys.paymentMethods + SnabbleAPI.serverName
        let oldData = self.keychain[oldKey]

        let keys = self.keychain.allKeys()
        for key in keys {
            if key.hasPrefix(SettingsKeys.paymentMethods) {
                try? self.keychain.remove(key)
            }
        }

        if let data = oldData {
            self.keychain[self.key] = data
        }
    }
}

public enum PaymentMethodDetails {
    private static let storage = PaymentMethodDetailStorage()

    public static func read() -> [PaymentMethodDetail] {
        return storage.read()
    }

    static func save(_ details: [PaymentMethodDetail]) {
        storage.save(details)
    }

    static func save(_ detail: PaymentMethodDetail) {
        storage.save(detail)
    }

    static func remove(_ detail: PaymentMethodDetail) {
        storage.remove(detail)
    }

    //
    /// initialize the storage for payment methods
    /// - Parameter firstStart: when `true` (on the first start of the app), remove all stored payment methods
    /// - Returns: true when any obsolete payment methods had to be removed
    ///
    /// This method silently removes any payment methods that have expired, most notably credit cards past
    /// their expiration date.
    public static func startup(_ firstStart: Bool) -> Bool {
        if firstStart {
            storage.removeAll()
        }

        removeExpired()

        return removeObsoleted()
    }

    private static func removeExpired() {
        var details = self.read()
        details.removeAll(where: \.isExpired)
        self.save(details)
    }

    private static func removeObsoleted() -> Bool {
        var details = self.read()
        let initialCount = details.count
        details.removeAll { detail -> Bool in
            switch detail.methodData {
            case .creditcard(let creditcardData):
                return creditcardData.version < CreditCardData.CreditCardRequestOrigin.version
            default:
                return false
            }
        }

        self.save(details)
        return initialCount != details.count
    }
}

// extensions for employee cards that can be used as payment methods
extension PaymentMethodDetails {
    public static func addTegutEmployeeCard(_ number: String, _ name: String, _ projectId: Identifier<Project>) {
        guard
            let cert = SnabbleAPI.certificates.first,
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
