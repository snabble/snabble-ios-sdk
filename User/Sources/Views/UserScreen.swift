//
//  UserScreen.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-19.
//

import SwiftUI

import SnabbleNetwork
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
    let user: SnabbleUser.User
    
    var onDeletion: () -> Void
    let onCompletion: (_ userDetails: User.Details) -> Void
    
    private static var sixteenYearAgo: Date {
        let sixteenYears: TimeInterval = 504_910_816
        return Date(timeIntervalSinceNow: -sixteenYears)
    }
    
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    public init(
        networkManager: NetworkManager,
        user: SnabbleUser.User,
        kind: Kind,
        onCompletion: @escaping (_ details: User.Details) -> Void,
        onDeletion: @escaping () -> Void
    ) {
        self.networkManager = networkManager
        self.user = user
        self.kind = kind
        self.onCompletion = onCompletion
        self.onDeletion = onDeletion
        
        _firstName = State(initialValue: self.user.firstName ?? "")
        _lastName = State(initialValue: self.user.lastName ?? "")
        _email = State(initialValue: self.user.email ?? "")
        if let dateOfBirth = self.user.dateOfBirth {
            _dateOfBirth = State(initialValue: dateOfBirth)
        } else {
            _dateOfBirth = State(initialValue: Self.sixteenYearAgo)
        }
        _street = State(initialValue: self.user.address?.street ?? "")
        _zip = State(initialValue: self.user.address?.zip ?? "")
        _city = State(initialValue: self.user.address?.city ?? "")
        _country = State(initialValue: self.user.address?.country ?? "")
        _state = State(initialValue: self.user.address?.state ?? "")
   }
    
    var fields: [Field] {
        user.metadata?.fields?.toFields() ?? []
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
                        UserDeleteButton {
                            DispatchQueue.main.async {
                                onDeletion()
                            }
                        }
                        .environment(networkManager)
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
                    if let countryCode = user.address?.country,
                       let country = Country.all.country(forCode: countryCode) {
                        countrySelection = country
                        
                        if let stateCode = user.address?.state,
                           let state = country.states?.state(forCode: stateCode) {
                            stateSelection = state
                        }
                    }
                }
                .onChange(of: countrySelection) { _, country in
                    if user.address?.country != country.code {
                        stateSelection = nil
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Asset.localizedString(forKey: kind.title))
                .padding()
            }
        }
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
            
            let details = User.Details(
                firstName: firstName,
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
                await MainActor.run {
                    onCompletion(details)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func isRequired(_ field: Field) -> Bool {
        return user.metadata?.fields?.first(where: { $0.id == field.rawValue })?.isRequired ?? false
    }
}

extension Array where Element == SnabbleUser.User.Field {
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
        let rootView = UserScreen(
            networkManager: networkManager,
            user: user,
            kind: .initial,
            onCompletion: { details in
                print(details)
            },
            onDeletion: {
                print("Delete User")
            }
        )
        
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
