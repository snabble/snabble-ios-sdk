//
//  PaymentMethodDetails.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess

protocol EncryptedPaymentData {
    // encrypted JSON string
    var encryptedPaymentData: String { get }

    // serial # of the certificate used to encrypt
    var serial: String { get }

    // name of this payment method for display
    var displayName: String { get }

    // check if this payment method data is expired
    var isExpired: Bool { get }

    var originType: AcceptedOriginType { get }
}

struct SepaData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    let displayName: String

    let originType = AcceptedOriginType.iban

    let isExpired = false

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, originType
    }

    private struct DirectDebitRequestOrigin: PaymentRequestOrigin {
        let name: String
        let iban: String
    }

    init?(_ gatewayCert: Data?, _ name: String, _ iban: String) {
        let requestOrigin = DirectDebitRequestOrigin(name: name, iban: iban)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = IBAN.displayName(iban)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)
    }
}

struct TegutEmployeeData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    let displayName: String

    let isExpired = false

    let originType = AcceptedOriginType.tegutEmployeeID

    let cardNumber: String

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, originType, cardNumber
    }

    private struct CardNumberOrigin: PaymentRequestOrigin {
        let cardNumber: String
    }

    init?(_ gatewayCert: Data?, _ number: String, _ name: String) {
        let requestOrigin = CardNumberOrigin(cardNumber: number)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = name
        self.cardNumber = number
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.cardNumber = (try? container.decodeIfPresent(String.self, forKey: .cardNumber)) ?? ""
    }
}

// unfortunately we have to maintain three different mappings to strings
public enum CreditCardBrand: String, Codable {
    // 1st mapping: from the reponse of the IPG card entry form
    case visa
    case mastercard
    case amex

    // 2nd mapping: to the `cardType` property of the encrypted payment data
    var cardType: String {
        switch self {
        case .visa: return "creditCardVisa"
        case .mastercard: return "creditCardMastercard"
        case .amex: return "creditCardAmericanExpress"
        }
    }

    // 3rd mapping: to the `paymentMethod` form field of the IPG card entry form
    var paymentMethod: String {
        switch self {
        case .visa: return "V"
        case .mastercard: return "M"
        case .amex: return "A"
        }
    }
}

struct CreditCardData: Codable, EncryptedPaymentData, Equatable {
    let encryptedPaymentData: String
    let serial: String
    let displayName: String
    let originType = AcceptedOriginType.ipgHostedDataID

    let cardHolder: String
    let brand: CreditCardBrand
    let expirationMonth: String
    let expirationYear: String
    let version: Int

    private struct CreditCardRequestOrigin: PaymentRequestOrigin {
        // bump this when we add properties to that might require invaliding previous versions
        static let version = 1

        let hostedDataID: String
        let hostedDataStoreID: String
        let cardType: String
    }

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, originType
        case cardHolder, brand, expirationMonth, expirationYear, version
    }

    init?(_ gatewayCert: Data?, _ cardHolder: String, _ cardNumber: String, _ brand: String, _ expMonth: String, _ expYear: String, _ hostedDataId: String, _ storeId: String) {
        guard !cardHolder.isEmpty, !cardNumber.isEmpty, !brand.isEmpty, !expMonth.isEmpty, !expYear.isEmpty, !hostedDataId.isEmpty else {
            return nil
        }

        guard let brand = CreditCardBrand(rawValue: brand.lowercased()) else {
            return nil
        }

        self.version = CreditCardRequestOrigin.version
        self.displayName = cardNumber
        self.cardHolder = cardHolder
        self.brand = brand
        self.expirationYear = expYear
        self.expirationMonth = expMonth

        let requestOrigin = CreditCardRequestOrigin(hostedDataID: hostedDataId, hostedDataStoreID: storeId, cardType: brand.cardType)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)

        self.cardHolder = try container.decode(String.self, forKey: .cardHolder)
        self.brand = try container.decode(CreditCardBrand.self, forKey: .brand)
        self.expirationMonth = try container.decode(String.self, forKey: .expirationMonth)
        self.expirationYear = try container.decode(String.self, forKey: .expirationYear)
        let version = try container.decodeIfPresent(Int.self, forKey: .version)
        self.version = version ?? CreditCardRequestOrigin.version
    }

    // the card's expiration date as a YYYY/MM/DD string with the last day of the month,
    // e.g. 2020/02/29 for expirationDate == 02/20202
    private var validUntil: String? {
        guard
            let year = Int(self.expirationYear),
            let month = Int(self.expirationMonth)
        else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.year = year
        dateComponents.month = month

        guard
            let firstDate = dateComponents.date,
            let lastDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDate)
        else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        return dateFormatter.string(from: lastDate)
    }

    var additionalData: [String: String] {
        var data = [
            "cardNumber": self.displayName
        ]

        if let validUntil = self.validUntil {
            data["validUntil"] = validUntil
        }

        return data
    }

    // the card's expiration date as usally displayed, e.g. 09/2020
    var expirationDate: String {
        return "\(self.expirationMonth)/\(self.expirationYear)"
    }

    var isExpired: Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else {
            return false
        }

        guard let expYear = Int(self.expirationYear), let expMonth = Int(self.expirationMonth) else {
            return false
        }

        let date = year * 100 + month
        let expiration = expYear * 100 + expMonth
        return expiration <= date
    }
}

struct PaydirektData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    let displayName: String

    let isExpired = false

    let originType = AcceptedOriginType.paydirektCustomerAuthorization

    let deviceId: String
    let deviceName: String
    let deviceFingerprint: String
    let deviceIpAddress: String

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, originType, deviceId, deviceName
        case deviceFingerprint, deviceIpAddress
    }

    private struct PaydirektOrigin: PaymentRequestOrigin {
        let clientID: String
        let customerAuthorizationURI: String
    }

    init?(_ gatewayCert: Data?, _ authorizationURI: String, _ auth: PaydirektAuthorization) {
        let requestOrigin = PaydirektOrigin(clientID: SnabbleAPI.clientId, customerAuthorizationURI: authorizationURI)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = "paydirekt"

        self.deviceId = auth.id
        self.deviceName = auth.name
        self.deviceFingerprint = auth.fingerprint
        self.deviceIpAddress = auth.ipAddress
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)

        self.deviceId = try container.decode(String.self, forKey: .deviceId)
        self.deviceName = try container.decode(String.self, forKey: .deviceName)
        self.deviceFingerprint = try container.decode(String.self, forKey: .deviceFingerprint)
        self.deviceIpAddress = try container.decode(String.self, forKey: .deviceIpAddress)
    }

    var additionalData: [String: String] {
        return [
            "deviceID": self.deviceId,
            "deviceName": self.deviceName,
            "deviceFingerprint": self.deviceFingerprint,
            "deviceIPAddress": self.deviceIpAddress
        ]
    }
}

enum PaymentMethodError: Error {
    case unknownMethodError(String)
}

enum PaymentMethodUserData: Codable, Equatable {
    case sepa(SepaData)
    case creditcard(CreditCardData)
    case tegutEmployeeCard(TegutEmployeeData)
    case paydirektAuthorization(PaydirektData)

    enum CodingKeys: String, CodingKey {
        case sepa, creditcard, tegutEmployeeCard, paydirektAuthorization
    }

    var data: EncryptedPaymentData {
        switch self {
        case .sepa(let sepadata): return sepadata
        case .creditcard(let creditcardData): return creditcardData
        case .tegutEmployeeCard(let tegutData): return tegutData
        case .paydirektAuthorization(let paydirektData): return paydirektData
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
        } else {
            throw PaymentMethodError.unknownMethodError("unknown payment method")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sepa(let sepaData): try container.encode(sepaData, forKey: .sepa)
        case .creditcard(let creditcardData): try container.encode(creditcardData, forKey: .creditcard)
        case .tegutEmployeeCard(let tegutData): try container.encode(tegutData, forKey: .tegutEmployeeCard)
        case .paydirektAuthorization(let paydirektData): try container.encode(paydirektData, forKey: .paydirektAuthorization)
        }
    }
}

public struct PaymentMethodDetail: Codable, Equatable {
    let methodData: PaymentMethodUserData

    init(_ sepaData: SepaData) {
        self.methodData = PaymentMethodUserData.sepa(sepaData)
    }

    init(_ creditcardData: CreditCardData) {
        self.methodData = PaymentMethodUserData.creditcard(creditcardData)
    }

    init(_ tegutData: TegutEmployeeData) {
        self.methodData = PaymentMethodUserData.tegutEmployeeCard(tegutData)
    }

    init(_ paydirektData: PaydirektData) {
        self.methodData = PaymentMethodUserData.paydirektAuthorization(paydirektData)
    }

    var displayName: String {
        return self.methodData.data.displayName
    }

    var encryptedData: String {
        return self.methodData.data.encryptedPaymentData
    }

    var additionalData: [String: String] {
        return self.methodData.additionalData
    }

    var serial: String {
        return self.methodData.data.serial
    }

    public var data: Snabble.PaymentMethodData {
        return Snabble.PaymentMethodData(self.displayName, self.encryptedData, self.originType, self.additionalData)
    }

    var isExpired: Bool {
        return self.methodData.data.isExpired
    }

    var rawMethod: RawPaymentMethod {
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
        }
    }

    var originType: AcceptedOriginType {
        return self.methodData.data.originType
    }
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

    func save(_ detail: PaymentMethodDetail, at index: Int?) {
        var details = self.read()

        if let index = index {
            details[index] = detail
        } else {
            details.append(detail)
        }

        self.save(details)
    }

    func remove(at index: Int) {
        var details = self.read()
        details.remove(at: index)
        self.save(details)
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

    static func save(_ detail: PaymentMethodDetail, at index: Int? = nil) {
        storage.save(detail, at: index)
    }

    static func remove(at index: Int) {
        storage.remove(at: index)
    }

    public static func startup(_ firstStart: Bool) {
        if firstStart {
            storage.removeAll()
        }

        removeExpired()
    }

    private static func removeExpired() {
        var details = self.read()

        for (index, detail) in details.reversed().enumerated() where detail.isExpired {
            details.remove(at: index)
        }

        self.save(details)
    }
}

// extensions for employee cards that can be used as payment methods
extension PaymentMethodDetails {
    public static func addTegutEmployeeCard(_ number: String, _ name: String) {
        guard
            let cert = SnabbleAPI.certificates.first,
            let employeeData = TegutEmployeeData(cert.data, number, name)
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
