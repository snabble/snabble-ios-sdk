//
//  SepaDataModel.swift
//  
//
//  Created by Uwe Tilemann on 22.11.22.
//

import Foundation

import SnabbleCore
import SnabbleAssetProviding
import SnabbleTheme

public enum SepaStrings: String {
    case iban
    case lastname = "name"
    case city
    case countryCode
    
    case payer
    case mandate
    
    case save
    
    case invalidIBAN
    case invalidIBANCountry
    case validIBAN
    
    public var localizedString: String {
        return Asset.localizedString(forKey: "Snabble.Payment.SEPA.\(self.rawValue)")
    }
}

public extension String {
    var ibanCountry: String? {
        if let index = self.firstIndexOf(charactersIn: "0123456789") {
            return String(self.prefix(upTo: index))
        }
        return nil
    }
    
    var ibanNumber: String? {
        if let index = self.firstIndexOf(charactersIn: "0123456789") {
            return String(self.suffix(from: index))
        }
        return nil
    }
}

extension Locale {
    var countryCode: String {
        let code = self.identifier
        let array = code.components(separatedBy: "_")
        
        if array.count > 1 {
            return array.last ?? code
        }
        return code
    }
}


@Observable
@MainActor
public final class SepaDataModel {
    public var formatter: IBANFormatter

    public var ibanCountry: String {
        didSet {
            if !ibanCountry.isEmpty {
                self.formatter = IBANFormatter(country: ibanCountry)
            }
            scheduleValidation()
        }
    }
    public var ibanNumber: String {
        didSet { scheduleValidation() }
    }
    public var lastname: String {
        didSet { scheduleValidation() }
    }
    public var city: String {
        didSet { scheduleValidation() }
    }

    public var mandateReference: String?
    public var mandateMarkup: String?

    public var isEditable: Bool {
        return paymentDetail == nil
    }

    @ObservationIgnored public private(set) var actionStream: AsyncStream<[String: Any]?>
    @ObservationIgnored private var actionContinuation: AsyncStream<[String: Any]?>.Continuation?

    public func send(_ action: sending [String: Any]?) {
        actionContinuation?.yield(action)
    }

    public var iban: String {
        if let detail = paymentDetail, case .payoneSepa(let data) = detail.methodData {
            return data.displayName
        }
        return isValid ? self.sanitzedIban : ""
    }

    public var countries: [String] {
          let all = IBAN.countries

          if PayoneSepaData.countries.count == 1, let countryCode = PayoneSepaData.countries.first {
              if countryCode == "*" {
                  return all.sorted()
              }
              return [countryCode]
          }
        return PayoneSepaData.countries.sorted()
    }

    private var paymentDetail: PaymentMethodDetail?

    private var projectId: Identifier<Project>?

    public var countryIsValid: Bool {
        return IBAN.length(self.ibanCountry.uppercased()) != nil
    }

    public var hasIbanLength: Bool {
        let length = (IBAN.length(self.ibanCountry.uppercased()) ?? 22)

        return self.sanitzedIban.count == length
    }

    public var ibanIsValid: Bool {
        return hasIbanLength && IBAN.verify(iban: self.sanitzedIban)
    }

    private var sanitzedIban: String {
        let country = self.ibanCountry.uppercased()
        let trimmed = self.ibanNumber.replacingOccurrences(of: " ", with: "")

        return country + trimmed
    }

    public var IBANLength: Int {
        return IBAN.length(self.ibanCountry.uppercased()) ?? 0
    }

    public enum Policy {
        case simple
        case extended
    }
    public private(set) var policy: Policy = .simple

    // output
    public var hintMessage = ""
    public var errorMessage: String = ""

    public var isValid = false {
        didSet {
            if isValid == true, errorMessage.isEmpty == false {
                self.errorMessage = ""
            }
        }
    }

    public var debounce: TimeInterval = 0.25
    public var minimumInputCount: Int = 2

    @ObservationIgnored private var validationTask: Task<Void, Never>?

    private func scheduleValidation() {
        guard isEditable else { return }
        validationTask?.cancel()
        let delay = debounce
        validationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.updateValidation()
        }
    }

    private func updateValidation() {
        let ibanCountryValid = IBAN.length(ibanCountry.uppercased()) != nil
        let ibanNumberValid = countryIsValid && (ibanIsValid || !hasIbanLength)

        if !ibanCountryValid && !ibanNumberValid {
            errorMessage = SepaStrings.invalidIBAN.localizedString
        } else if !ibanCountryValid {
            errorMessage = SepaStrings.invalidIBANCountry.localizedString
        } else if !ibanNumberValid {
            errorMessage = SepaStrings.invalidIBAN.localizedString
        } else if sanitzedIban.count < IBANLength {
            errorMessage = ""
        } else if !ibanIsValid {
            errorMessage = SepaStrings.invalidIBAN.localizedString
        } else {
            errorMessage = ""
        }

        if let hintState = formatter.hintState {
            hintMessage = hintState.localizedString
        } else {
            hintMessage = ""
        }

        let lastnameValid = lastname.count >= minimumInputCount
        let cityValid = city.count >= 3
        isValid = hasIbanLength && lastnameValid && ibanCountryValid && ibanNumberValid && (cityValid || policy == .simple)
    }

    public init(paymentDetail: PaymentMethodDetail? = nil, iban: String, lastname: String, city: String? = nil, countryCode: String = "DE", projectId: Identifier<Project>? = nil) {
        self.paymentDetail = paymentDetail
        self.projectId = projectId
        self.policy = (city != nil) ? .extended : .simple

        let country = iban.ibanCountry ?? countryCode
        self.formatter = IBANFormatter(country: country)
        self.ibanCountry = country
        self.ibanNumber = iban.ibanNumber ?? ""
        self.lastname = lastname
        self.city = city ?? ""

        var cont: AsyncStream<[String: Any]?>.Continuation!
        actionStream = AsyncStream { cont = $0 }
        actionContinuation = cont

        scheduleValidation()
    }

    public convenience init(iban: String? = nil, countryCode: String = "DE", projectId: Identifier<Project>) {
        self.init(iban: iban ?? "", lastname: "", city: "", countryCode: countryCode, projectId: projectId)
    }

    public convenience init(detail: PaymentMethodDetail, projectId: Identifier<Project>?) {
        self.init(paymentDetail: detail, iban: detail.displayName, lastname: "", city: "", projectId: projectId)
    }

    deinit {
        actionContinuation?.finish()
        validationTask?.cancel()
    }
}

extension SepaDataModel {
    public var paymentDetailName: String? {
        if let detail = paymentDetail, case .payoneSepa(let data) = detail.methodData {
            return data.lastName
        }
        return nil
    }

    public var paymentDetailMandate: String? {
        if let detail = paymentDetail, case .payoneSepa(let data) = detail.methodData {
            return data.mandateReference
        }
        return nil
    }

    public var paymentDetailMarkup: String? {
        if let detail = paymentDetail, case .payoneSepa(let data) = detail.methodData {
            return data.mandateMarkup
        }
        return nil
    }

    public var imageName: String? {
        return paymentDetail?.imageName
    }
}

extension SepaDataModel {
    public func remove() {
        guard let detail = paymentDetail else {
            return
        }
        PaymentMethodDetails.remove(detail)

        self.ibanNumber = ""
        self.lastname = ""
        self.city = ""
        self.paymentDetail = nil

        scheduleValidation()
    }

    public func save() async throws {
        if self.isValid,
           let cert = Snabble.shared.certificates.first,
           let sepaData = PayoneSepaData(cert.data, iban: self.iban, lastName: self.lastname, city: self.city, countryCode: self.ibanCountry, projectId: self.projectId ?? SnabbleCI.project.id, mandateReference: self.mandateReference, mandateMarkup: self.mandateMarkup) {

            let detail = PaymentMethodDetail(sepaData)
            PaymentMethodDetails.save(detail)

            paymentDetail = detail
        } else {
            throw PaymentMethodError.encryptionError
        }
    }
}
