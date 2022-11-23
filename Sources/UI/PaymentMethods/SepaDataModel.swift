//
//  SepaDataModel.swift
//  
//
//  Created by Uwe Tilemann on 22.11.22.
//

import Foundation
import Combine
import SnabbleCore
import UIKit

public enum SepaStrings: String {
    case iban
    case lastname
    case city
    case countryCode
    
    case save
    
    case invalidIBAN
    case invalidIBANCountry
    case invalidIBANNumber

    case missingLastname
    case missingCity
    case missingCountry
    
    public var localizedString: String {
        return Asset.localizedString(forKey: "Snabble.Payment.SEPA.\(self.rawValue)")
    }
}

public extension String {
    var ibanCountry: String? {
        let index = self.firstIndex { (character) -> Bool in
            if let unicodeScalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 {
                return CharacterSet(charactersIn: "0123456789").contains(unicodeScalar)
            }
            return false
        }
        if let index = index {
            return String(self.prefix(upTo:index))
        }
        return nil
    }
    
    var ibanNumber: String? {
        let index = self.firstIndex { (character) -> Bool in
            if let unicodeScalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 {
                return CharacterSet(charactersIn: "0123456789").contains(unicodeScalar)
            }
            return false
        }
        if let index = index {
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
    
    @Published public var ibanCountry: String
    @Published public var ibanNumber: String
    @Published public var lastname: String
    @Published public var city: String
    @Published public var countryCode: String
    
    /// subscribe to this Publisher to start your login process
    public var actionPublisher = PassthroughSubject<Void, Never>()

    public var iban: String {
        return isValid ? self.sanitzedIban : ""
    }
    
    private var countryIsValid: Bool {
        return IBAN.length(self.ibanCountry.uppercased()) != nil
    }
    private var ibanIsValid: Bool {
        let length = (IBAN.length(self.ibanCountry.uppercased()) ?? 22)
        let iban = self.sanitzedIban
        
        return iban.count == length && IBAN.verify(iban: iban)
    }
    private var sanitzedIban: String {
        let country = self.ibanCountry.uppercased()
        let trimmed = self.ibanNumber.replacingOccurrences(of: " ", with: "")
        
        return country + trimmed
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
    
    private var isLastnameValidPublisher: AnyPublisher<Bool, Never> {
        $lastname
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var isIbanCountryValidPublisher: AnyPublisher<Bool, Never> {
        $ibanCountry
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { code in
                return IBAN.placeholder(code.uppercased()) != nil
            }
            .eraseToAnyPublisher()
    }

    private var isIbanNumberValidPublisher: AnyPublisher<Bool, Never> {
        $ibanNumber
            .debounce(for: debounce, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { _ in
                return self.countryIsValid && self.ibanIsValid
            }
            .eraseToAnyPublisher()
    }
    
    private var isCityValidPublisher: AnyPublisher<Bool, Never> {
        $city
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(3)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isFormValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4(isLastnameValidPublisher, isIbanCountryValidPublisher, isIbanNumberValidPublisher, isCityValidPublisher)
            .map { lastnameIsValid, ibanCountryIsValid, ibanNumberIsValid, cityIsValid in
                return lastnameIsValid && ibanCountryIsValid && ibanNumberIsValid && (cityIsValid || self.policy == .simple)
            }
            .eraseToAnyPublisher()
    }
    
    public init(iban: String, lastname: String, city: String? = nil, countryCode: String? = nil) {
        self.policy = (city != nil && countryCode != nil) ? .extended : .simple

        self.ibanCountry = iban.ibanCountry ?? countryCode ?? ""
        self.ibanNumber = iban.ibanNumber ?? ""
        self.lastname = lastname
        self.city = city ?? ""
        self.countryCode = countryCode ?? ""
        
        isLastnameValidPublisher
            .combineLatest(isIbanCountryValidPublisher, isIbanNumberValidPublisher, isCityValidPublisher)
            .map { validLastname, validIbanCountry, validIbanNumber, validCity in
                if !validIbanCountry && !validIbanNumber {
                    return SepaStrings.invalidIBAN.localizedString
                } else if !validIbanCountry {
                    return SepaStrings.invalidIBANCountry.localizedString
                } else if !validIbanNumber {
                    return SepaStrings.invalidIBANNumber.localizedString
                } else if !validLastname {
                    return SepaStrings.missingLastname.localizedString
                } else if !validCity && self.policy == .extended {
                    return SepaStrings.missingCity.localizedString
                }
                return ""
            }
            .assign(to: \SepaDataModel.hintMessage, onWeak: self)
            .store(in: &cancellables)
        
        isFormValidPublisher
            .assign(to: \.isValid, onWeak: self)
            .store(in: &cancellables)

    }
    public convenience init() {
        self.init(iban: "", lastname: "", city: "", countryCode: Locale.current.countryCode)
    }
    public convenience init(detail: PaymentMethodDetail) {
        self.init(iban: detail.displayName, lastname: "", city: "", countryCode: Locale.current.countryCode)
    }
}

