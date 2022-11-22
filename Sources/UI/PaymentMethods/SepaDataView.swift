//
//  SepaDataView.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import SwiftUI
import Combine

public protocol SepaDataProviding {
    var iban: String { get }
    var lastname: String { get }
    var city: String? { get }
    var countryCode: String? { get }
}

public struct SepaAccount: SepaDataProviding {
    
    public var iban: String
    public var lastname: String
    public var city: String?
    public var countryCode: String?

    init(iban: String, lastname: String, city: String? = nil, countryCode: String? = nil) {
        self.iban = iban
        self.lastname = lastname
        self.city = city
        self.countryCode = countryCode
    }
}

public enum SepaStrings: String {
    case iban
    case lastname
    case city
    case countryCode
    
    case save
    
    case invalidIBAN
    case invalidName
    case missingLastname
    
    case missingCity
    case missingCountry
    
    public var localizedString: String {
        return Asset.localizedString(forKey: "Snabble.Payment.SEPA.\(self.rawValue)")
    }
}

public final class SepaDataModel: SepaDataProviding, ObservableObject {

    @Published public var iban: String
    @Published public var lastname: String
    @Published public var city: String?
    @Published public var countryCode: String?

    public enum Policy {
        case simple
        case extended
    }
    public private(set) var policy: Policy = .simple
    
    init(policy: SepaDataModel.Policy, iban: String, lastname: String, city: String? = nil, countryCode: String? = nil) {
        self.policy = policy
        self.iban = iban
        self.lastname = lastname
        self.city = city
        self.countryCode = countryCode
    }

    /// Emits on action
    /// - `Output` is the current selected account
    public let actionPublisher = PassthroughSubject<SepaDataProviding, Never>()
  
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
    public var minimumInputCount: Int = 3
    
    private var cancellables = Set<AnyCancellable>()
}

public struct SepaDataView: View {
    @ObservedObject var model: SepaDataModel
    @State private var action = false

    public init(model: SepaDataModel) {
        self.model = model
    }
    
    @ViewBuilder
    var button: some View {
        Button(action: {
            action.toggle()
        }) {
            Text(SepaStrings.save.localizedString)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
        .disabled(!self.model.isValid)
        .opacity(!self.model.isValid ? 0.5 : 1.0)
    }

    public var body: some View {
        Form {
            Section(
                content: {
                    TextField(SepaStrings.lastname.localizedString, text: $model.iban)
                },
                footer: {
                    Text(model.hintMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                })
            Section(
                content: {
                    button
                },
                footer: {
                    if !model.errorMessage.isEmpty {
                        Text(model.errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                })
        }
    }
}

