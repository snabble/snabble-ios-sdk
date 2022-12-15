//
//  SepaDataModel.swift
//  
//
//  Created by Uwe Tilemann on 22.11.22.
//

import Foundation
import Combine
import SnabbleCore

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
    case invalidIBANNumber

    case missingIBAN
    case missingName
    case missingCity
    case missingCountry
    
    public var localizedString: String {
        return Asset.localizedString(forKey: "Snabble.Payment.SEPA.\(self.rawValue)")
    }
}

extension String {
    func firstIndexOf(charactersIn string: String) -> Index? {
        let index = self.firstIndex { (character) -> Bool in
            if let unicodeScalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 {
                return CharacterSet(charactersIn: string).contains(unicodeScalar)
            }
            return false
        }
        return index
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

public final class SepaDataModel: ObservableObject {
    
    public let formatter = IBANFormatter()

    @Published public var ibanCountry: String {
        didSet {
            if let placeholder = IBAN.placeholder(ibanCountry) {
                formatter.placeholder = placeholder
            }
        }
    }
    @Published public var ibanNumber: String
    @Published public var lastname: String
    @Published public var city: String
    @Published public var countryCode: String

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

    private var paymentDetail: PaymentMethodDetail? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private var projectId: Identifier<Project>?

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

    private var countryIsValid: Bool {
        return IBAN.length(self.ibanCountry.uppercased()) != nil
    }

    private var hasIbanLength: Bool {
        let length = (IBAN.length(self.ibanCountry.uppercased()) ?? 22)
        
        return self.sanitzedIban.count == length
    }

    private var ibanIsValid: Bool {
        return hasIbanLength && IBAN.verify(iban: self.sanitzedIban)
    }

    private var sanitzedIban: String {
        let country = self.ibanCountry.uppercased()
        let trimmed = self.ibanNumber.replacingOccurrences(of: " ", with: "")
        
        return country + trimmed
    }

    private var IBANLength: Int {
        return IBAN.length(self.ibanCountry.uppercased()) ?? 0
    }

    public enum Policy {
        case simple
        case extended
    }
    public private(set) var policy: Policy = .simple

    @Published public var isValid = false {
        didSet {
            if errorMessage.isEmpty == false {
                self.errorMessage = ""
            }
        }
    }

    // output
    @Published public var hintMessage = ""
    @Published public var errorMessage: String = ""

    public var debounce: RunLoop.SchedulerTimeType.Stride = 0.5
    public var minimumInputCount: Int = 2

    private var cancellables = Set<AnyCancellable>()

    private lazy var isLastnameValidPublisher: AnyPublisher<Bool, Never> = {
        $lastname
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    private lazy var isIbanCountryValidPublisher: AnyPublisher<Bool, Never> = {
        $ibanCountry
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { code in
                return IBAN.placeholder(code.uppercased()) != nil
            }
            .eraseToAnyPublisher()
    }()

    private lazy var isIbanNumberValidPublisher: AnyPublisher<Bool, Never> = {
        $ibanNumber
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { _ in
                return self.countryIsValid && (self.ibanIsValid || !self.hasIbanLength)
            }
            .eraseToAnyPublisher()
    }()

    private lazy var isCityValidPublisher: AnyPublisher<Bool, Never> = {
        $city
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(3)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    private lazy var isFormValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest4(isLastnameValidPublisher, isIbanCountryValidPublisher, isIbanNumberValidPublisher, isCityValidPublisher)
            .map { lastnameIsValid, ibanCountryIsValid, ibanNumberIsValid, cityIsValid in
                guard self.hasIbanLength else {
                    return false
                }
                return lastnameIsValid && ibanCountryIsValid && ibanNumberIsValid && (cityIsValid || self.policy == .simple)
            }
            .eraseToAnyPublisher()
    }()

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
                if self.sanitzedIban.count < self.IBANLength {
                    return ""
                }
                if !self.ibanIsValid {
                    return SepaStrings.invalidIBAN.localizedString
                }
                return ""
            }
            .assign(to: \SepaDataModel.hintMessage, onWeak: self)
            .store(in: &cancellables)

        isFormValidPublisher
            .assign(to: \.isValid, onWeak: self)
            .store(in: &cancellables)
    }

    public init(paymentDetail: PaymentMethodDetail? = nil, iban: String, lastname: String, city: String? = nil, countryCode: String? = "DE", projectId: Identifier<Project>? = nil) {
        self.paymentDetail = paymentDetail
        self.projectId = projectId
        self.policy = (city != nil && countryCode != nil) ? .extended : .simple

        self.ibanCountry = iban.ibanCountry ?? countryCode ?? ""
        self.ibanNumber = iban.ibanNumber ?? ""
        self.lastname = lastname
        self.city = city ?? ""
        self.countryCode = countryCode ?? ""

        setupPublishers()
    }

    public convenience init(projectId: Identifier<Project>) {
        self.init(iban: "", lastname: "", city: "", projectId: projectId)
    }

    public convenience init(detail: PaymentMethodDetail, projectId: Identifier<Project>?) {
        self.init(paymentDetail: detail, iban: detail.displayName, lastname: "", city: "", projectId: projectId)
    }
}

extension SepaDataModel {
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
           let sepaData = PayoneSepaData(cert.data, iban: self.iban, lastName: self.lastname, city: self.city, countryCode: self.countryCode, projectId: self.projectId ?? SnabbleCI.project.id, mandateReference: self.mandateReference, mandateMarkup: self.mandateMarkup) {
            
            let detail = PaymentMethodDetail(sepaData)
            PaymentMethodDetails.save(detail)
            
            paymentDetail = detail

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            throw PaymentMethodError.encryptionError
        }
    }
}
