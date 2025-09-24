//
//  SepaDataModel.swift
//  
//
//  Created by Uwe Tilemann on 22.11.22.
//

import Foundation
import Combine
import Observation
import SnabbleCore
import SnabbleAssetProviding

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

extension Publisher where Output == String?, Failure == Never {
    func minimumOptional(_ minimum: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input?.count ?? 0 >= minimum
        }
        .eraseToAnyPublisher()
    }
    func maximumOptional(_ maximum: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input?.count ?? 0 <= maximum
        }
        .eraseToAnyPublisher()
    }
    func exactOptional(_ length: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input?.count == length
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == String, Failure == Never {
    func minimum(_ minimum: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input.count >= minimum
        }
        .eraseToAnyPublisher()
    }
    func maximum(_ maximum: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input.count <= maximum
        }
        .eraseToAnyPublisher()
    }
    func exact(_ length: Int) -> AnyPublisher<Bool, Never> {
        map { input in
            input.count == length
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    func assign<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        onWeak object: Root
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

@MainActor
@Observable
public final class SepaDataModel {

    public var formatter: IBANFormatter

    // Internal subjects for Combine compatibility
    private let ibanCountrySubject = CurrentValueSubject<String, Never>("")
    private let ibanNumberSubject = CurrentValueSubject<String, Never>("")
    private let lastnameSubject = CurrentValueSubject<String, Never>("")
    private let citySubject = CurrentValueSubject<String, Never>("")

    public var ibanCountry: String {
        didSet {
            if !ibanCountry.isEmpty {
                self.formatter = IBANFormatter(country: ibanCountry)
            }
            ibanCountrySubject.send(ibanCountry)
        }
    }
    public var ibanNumber: String {
        didSet {
            ibanNumberSubject.send(ibanNumber)
        }
    }
    public var lastname: String {
        didSet {
            lastnameSubject.send(lastname)
        }
    }
    public var city: String {
        didSet {
            citySubject.send(city)
        }
    }

    public var mandateReference: String?
    public var mandateMarkup: String?

    public var isEditable: Bool {
        return paymentDetail == nil
    }

    /// subscribe to this Publisher to start your login process
    public var actionPublisher = PassthroughSubject<[String: Any]?, Never>()

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

    private var paymentDetail: PaymentMethodDetail? {
        didSet {
            // @Observable automatically handles change notifications
        }
    }

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

    // Internal subjects for output properties
    private let hintMessageSubject = CurrentValueSubject<String, Never>("")
    private let errorMessageSubject = CurrentValueSubject<String, Never>("")
    private let isValidSubject = CurrentValueSubject<Bool, Never>(false)

    // output
    public var hintMessage = "" {
        didSet {
            hintMessageSubject.send(hintMessage)
        }
    }
    public var errorMessage: String = "" {
        didSet {
            errorMessageSubject.send(errorMessage)
        }
    }

    public var isValid = false {
        didSet {
            if isValid == true, errorMessage.isEmpty == false {
                self.errorMessage = ""
            }
            isValidSubject.send(isValid)
        }
    }

    public var debounce: RunLoop.SchedulerTimeType.Stride = 0.25
    public var minimumInputCount: Int = 2

    private var cancellables = Set<AnyCancellable>()

    private var isLastnameValidPublisher: AnyPublisher<Bool, Never> {
        lastnameSubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isIbanCountryValidPublisher: AnyPublisher<Bool, Never> {
        ibanCountrySubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { code in
                return IBAN.length(code.uppercased()) != nil
            }
            .eraseToAnyPublisher()
    }

    private var isIbanNumberValidPublisher: AnyPublisher<Bool, Never> {
        ibanNumberSubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { _ in
                return self.countryIsValid && (self.ibanIsValid || !self.hasIbanLength)
            }
            .eraseToAnyPublisher()
    }

    private var isCityValidPublisher: AnyPublisher<Bool, Never> {
        citySubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(3)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isFormValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4(isLastnameValidPublisher, isIbanCountryValidPublisher, isIbanNumberValidPublisher, isCityValidPublisher)
            .map { lastnameIsValid, ibanCountryIsValid, ibanNumberIsValid, cityIsValid in
                guard self.hasIbanLength else {
                    return false
                }
                return lastnameIsValid && ibanCountryIsValid && ibanNumberIsValid && (cityIsValid || self.policy == .simple)
            }
            .eraseToAnyPublisher()
    }

    private func setupPublishers() {
        guard isEditable else {
            return
        }

        isIbanCountryValidPublisher
            .combineLatest(isIbanNumberValidPublisher)
            .map { validIbanCountry, validIbanNumber in
                if !validIbanCountry && !validIbanNumber {
                    return SepaStrings.invalidIBAN.localizedString
                } else if !validIbanCountry {
                    return SepaStrings.invalidIBANCountry.localizedString
                } else if !validIbanNumber {
                    return SepaStrings.invalidIBAN.localizedString
                }
                // no error message while entering iban and entered length < required length
                if self.sanitzedIban.count < self.IBANLength {
                    return ""
                }
                // check for valid iban
                if !self.ibanIsValid {
                    return SepaStrings.invalidIBAN.localizedString
                }
                return ""
            }
            .assign(to: \SepaDataModel.errorMessage, onWeak: self)
            .store(in: &cancellables)

        isIbanNumberValidPublisher
            .map { _ in
                if let hintState = self.formatter.hintState {
                    return hintState.localizedString
                }
                return ""
            }
            .assign(to: \SepaDataModel.hintMessage, onWeak: self)
            .store(in: &cancellables)

        isFormValidPublisher
            .assign(to: \.isValid, onWeak: self)
            .store(in: &cancellables)
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

        setupPublishers()
    }

    public convenience init(iban: String? = nil, countryCode: String = "DE", projectId: Identifier<Project>) {
        self.init(iban: iban ?? "", lastname: "", city: "", countryCode: countryCode, projectId: projectId)
    }

    public convenience init(detail: PaymentMethodDetail, projectId: Identifier<Project>?) {
        self.init(paymentDetail: detail, iban: detail.displayName, lastname: "", city: "", projectId: projectId)
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

        setupPublishers()
    }

    public func save() async throws {
        if self.isValid,
           let cert = Snabble.shared.certificates.first,
           let sepaData = PayoneSepaData(cert.data, iban: self.iban, lastName: self.lastname, city: self.city, countryCode: self.ibanCountry, projectId: self.projectId ?? SnabbleCI.project.id, mandateReference: self.mandateReference, mandateMarkup: self.mandateMarkup) {

            let detail = PaymentMethodDetail(sepaData)
            PaymentMethodDetails.save(detail)

            paymentDetail = detail

            // @Observable automatically handles change notifications
        } else {
            throw PaymentMethodError.encryptionError
        }
    }
}
