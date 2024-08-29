//
//  UserScreen.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-19.
//

import SwiftUI

import SnabbleCore
import SnabbleNetwork
import SnabblePhoneAuth
import SnabbleUser
import SnabbleAssetProviding

public struct UserScreen: View {
    public enum Kind {
        case initial
        case management
        
        var title: String {
            switch self {
            case .initial:
                "Snabble.Account.UserDetails.title"
            case .management:
                "Snabble.Account.UserDetails.Change.title"
            }
        }
        
        var message: String {
            switch self {
            case .initial:
                "Snabble.Account.UserDetails.description"
            case .management:
                "Snabble.Account.UserDetails.Change.description"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .initial:
                "Snabble.Account.UserDetails.buttonLabel"
            case .management:
                "Snabble.Account.UserDetails.Change.buttonLabel"
            }
        }
    }
    @Environment(\.dismiss) var dismiss
    
    let kind: Kind
    
    let networkManager: NetworkManager
    let user: SnabbleNetwork.User
    
    private static var sixteenYearAgo: Date {
        let sixteenYears: TimeInterval = 504_910_816
        return Date(timeIntervalSinceNow: -sixteenYears)
    }
    
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    public init(networkManager: NetworkManager, user: SnabbleUser.User, kind: Kind) {
        self.networkManager = networkManager
        self.user = .init(user: user)
        self.kind = kind
        
        _firstName = State(initialValue: self.user.details?.firstName ?? "")
        _lastName = State(initialValue: self.user.details?.lastName ?? "")
        _email = State(initialValue: self.user.details?.email ?? "")
        if let dateOfBirth = self.user.details?.dateOfBirth,
           let date = Self.dateFormatter.date(from: dateOfBirth) { // yyyy-MM-dd
            _dateOfBirth = State(initialValue: date)
        } else {
            _dateOfBirth = State(initialValue: Self.sixteenYearAgo)
        }
        _street = State(initialValue: self.user.details?.street ?? "")
        _zip = State(initialValue: self.user.details?.zip ?? "")
        _city = State(initialValue: self.user.details?.city ?? "")
        _country = State(initialValue: self.user.details?.country ?? "")
        _state = State(initialValue: self.user.details?.state ?? "")
   }
    
    var fields: [Field] {
        user.fields?.toFields() ?? []
    }
    
    enum Field: String, Swift.Identifiable, Hashable {
        var id: Self { self }

        case firstName
        case lastName
        case email
        case dateOfBirth
        case street
        case zip
        case city
        case country
    }
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var dateOfBirth: Date
    @State private var street: String
    @State private var zip: String
    @State private var city: String
    @State private var country: String
    @State private var state: String
    
    @State private var countrySelection: Country = Country.germany
    @State private var stateSelection: Country.State?

    @State private var errorMessage: String?
    
    @State private var isLoading: Bool = false
    @State private var showAccountConfirmation: Bool = false

    @FocusState private var focusField: Field?
    
    private var isButtonEnabled: Bool {
        if isRequired(.firstName), firstName.isEmpty {
            return false
        }
        if isRequired(.lastName), lastName.isEmpty {
            return false
        }
        if isRequired(.email), email.isEmpty {
            return false
        }
        if isRequired(.dateOfBirth), dateOfBirth.timeIntervalSince(Self.sixteenYearAgo) > 0 {
            return false
        }
        if isRequired(.street), street.isEmpty {
            return false
        }
        if isRequired(.zip), zip.isEmpty {
            return false
        }
        if isRequired(.city), city.isEmpty {
            return false
        }
        return true
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(Asset.localizedString(forKey: kind.message))
                        .multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        ForEach(fields, id: \.id) { field in
                            switch field {
                            case .firstName:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.firstName"), text: $firstName)
                                    .focused($focusField, equals: .firstName)
                                    .textContentType(.givenName)
                                    .keyboardType(.default)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.firstName)
                                    }
                                    .disabled(isLoading)
                            case .lastName:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.lastName"), text: $lastName)
                                    .focused($focusField, equals: .lastName)
                                    .textContentType(.familyName)
                                    .keyboardType(.default)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.lastName)
                                    }
                                    .disabled(isLoading)
                            case .email:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.email"), text: $email)
                                    .focused($focusField, equals: .email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.email)
                                    }
                                    .disabled(isLoading)
                            case .dateOfBirth:
                                DatePicker(Asset.localizedString(forKey: "Snabble.Account.UserDetails.dateOfBirth"),
                                           selection: $dateOfBirth,
                                           in: ...Self.sixteenYearAgo,
                                           displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .focused($focusField, equals: .dateOfBirth)
                                .padding(12)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onSubmit {
                                    focusField = fields.after(.dateOfBirth)
                                }
                                .disabled(isLoading)
                            case .street:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.street"), text: $street)
                                    .focused($focusField, equals: .street)
                                    .textContentType(.streetAddressLine1)
                                    .keyboardType(.default)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.street)
                                    }
                                    .disabled(isLoading)
                            case .zip:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.zip"), text: $zip)
                                    .focused($focusField, equals: .zip)
                                    .textContentType(.postalCode)
                                    .keyboardType(.numberPad)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.zip)
                                    }
                                    .disabled(isLoading)
                            case .city:
                                TextField(Asset.localizedString(forKey: "Snabble.Account.UserDetails.city"), text: $city)
                                    .focused($focusField, equals: .city)
                                    .textContentType(.addressCity)
                                    .keyboardType(.default)
                                    .submitLabel(.continue)
                                    .padding(12)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onSubmit {
                                        focusField = fields.after(.city)
                                    }
                                    .disabled(isLoading)
                            case .country:
                                CountryButtonView(
                                    countries: Country.all,
                                    selectedCountry: $countrySelection,
                                    selectedState: $stateSelection
                                )
                                .focused($focusField, equals: .country)
                                .disabled(isLoading)
                            }
                        }
                    }
                    PrimaryButtonView(
                        title: Asset.localizedString(forKey: kind.buttonTitle),
                        disabled: Binding(get: { !isButtonEnabled || isLoading }, set: { _ in }),
                        onAction: {
                            self.update(firstName: firstName,
                                        lastName: lastName,
                                        email: email,
                                        dateOfBirth: dateOfBirth,
                                        street: street,
                                        zip: zip,
                                        city: city,
                                        country: countrySelection.code,
                                        state: stateSelection?.code ?? "")
                        })
                    if kind == .management {
                        AccountDeleteButton(networkManager: networkManager, onCompletion: {
                            UserDefaults.standard.setUserSignedIn(false)
                            Snabble.shared.user = nil
                            killApp()
                        })
                    }
                    
                    if isLoading {
                        ProgressView()
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .onAppear {
                    if let countryCode = user.details?.country,
                       let country = Country.all.country(forCode: countryCode) {
                        countrySelection = country
                        
                        if let stateCode = user.details?.state,
                           let state = country.states?.state(forCode: stateCode) {
                            stateSelection = state
                        }
                    }
                }
                .onChange(of: countrySelection) { _, country in
                    if user.details?.country != country.code {
                        stateSelection = nil
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Asset.localizedString(forKey: kind.title))
                .padding()
            }
        }
    }

    private func killApp() {
        let application = UIApplication.shared
        let suspend = #selector(URLSessionTask.suspend)
        application.sendAction(suspend, to: application, from: nil, for: nil)
        
        Thread.sleep(forTimeInterval: 1)
        
        exit(0)
    }
    
    // swiftlint:disable:next function_parameter_count
    private func update(firstName: String,
                        lastName: String,
                        email: String,
                        dateOfBirth: Date,
                        street: String,
                        zip: String,
                        city: String,
                        country: String,
                        state: String) {
        Task {
            let details = SnabbleNetwork.User.Details(firstName: firstName,
                                                      lastName: lastName,
                                                      email: email,
                                                      dateOfBirth: Self.dateFormatter.string(from: dateOfBirth),
                                                      street: street,
                                                      zip: zip,
                                                      city: city,
                                                      country: country,
                                                      state: state)
            let endpoint = Endpoints.User.update(details: details)
            do {
                isLoading = true
                try await networkManager.publisher(for: endpoint)
                DispatchQueue.main.async {
                    user.update(withDetails: details)
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func isRequired(_ field: Field) -> Bool {
        return user.fields?.first(where: { $0.id == field.rawValue })?.isRequired ?? false
    }
}

extension Array where Element == SnabbleNetwork.User.Field {
    func toFields() -> [UserScreen.Field] {
        compactMap { element in
            switch element.id {
            case "firstName":
                return .firstName
            case "lastName":
                return .lastName
            case "email":
                return .email
            case "street":
                return .street
            case "dateOfBirth":
                return .dateOfBirth
            case "zip":
                return .zip
            case "city":
                return .city
            case "country":
                return .country
            default:
                return nil
            }
        }
    }
}

class UserScreenViewController: UIHostingController<UserScreen> {
    init(networkManager: NetworkManager, user: SnabbleUser.User) {
        super.init(rootView: UserScreen(networkManager: networkManager, user: user, kind: .initial))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
