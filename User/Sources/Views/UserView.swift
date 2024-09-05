//
//  SwiftUIView.swift
//  
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI
import SnabbleAssetProviding

private extension UserField {
    func next(in array: [UserField]) -> UserField? {
        guard let currentIndex = array.firstIndex(of: self) else {
            return nil
        }
        guard currentIndex < array.count - 1 else {
            return nil
        }
        let nextIndex = (currentIndex + 1) % array.count
        return array[nextIndex]
    }
}

private struct UserTextFieldView: View {
    let userField: UserField
    
    @Binding var text: String
    @Binding var disabled: Bool
    
    var body: some View {
        TextField(Asset.localizedString(forKey: userField.prompt), text: $text)
            .textContentType(userField.contentType)
            .keyboardType(userField.keyboardType)
            .submitLabel(.continue)
            .padding(12)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .disabled(disabled)
    }
}

public struct UserView: View {
    @Binding var user: User?
    let fields: [UserField]
    let requiredFields: [UserField]
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var dateOfBirth: Date
    @State private var street: String = ""
    @State private var zip: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var state: String = ""

    @State private var countrySelection: Country = Country.germany
    @State private var stateSelection: Country.State?

    let callingCodes: [CallingCode] = CallingCode.all
    @State var callingCode: CallingCode = CallingCode.germany

    @State private var disabled: Bool = false
    
    @FocusState private var focusField: UserField?
    
    public init(user: Binding<User?>, fields: [UserField] = UserField.allCases, requiredFields: [UserField] = UserField.allCases) {
        self._user = user
        self.fields = fields
        self.requiredFields = requiredFields
        
        var callingCode: CallingCode = .germany
        if let code = user.wrappedValue?.phone?.code {
            callingCode = CallingCode.all.callingCode(forCode: code) ?? callingCode
        }
#if DEBUG
        self._firstName = State(initialValue: user.wrappedValue?.firstName ?? "Foo")
        self._lastName = State(initialValue: user.wrappedValue?.lastName ?? "Bar")
        self._email = State(initialValue: user.wrappedValue?.email ?? "foo@bar.com")
        self._callingCode = State(initialValue: callingCode)
        self._phoneNumber = State(initialValue: user.wrappedValue?.phone?.number ?? "177 8765432")
        self._dateOfBirth = State(initialValue: user.wrappedValue?.dateOfBirth ?? Self.sixteenYearAgo)
        self._street = State(initialValue: user.wrappedValue?.address?.street ?? "Mainroad 55")
        self._zip = State(initialValue: user.wrappedValue?.address?.zip ?? "12345")
        self._city = State(initialValue: user.wrappedValue?.address?.city ?? "Jupiter")
        self._country = State(initialValue: user.wrappedValue?.address?.country ?? Country.germany.code)
        self._state = State(initialValue: user.wrappedValue?.address?.state ?? "")
#else
        self._firstName = State(initialValue: user.wrappedValue?.firstName ?? "")
        self._lastName = State(initialValue: user.wrappedValue?.lastName ?? "")
        self._email = State(initialValue: user.wrappedValue?.email ?? "")
        self._callingCode = State(initialValue: callingCode)
        self._phoneNumber = State(initialValue: user.wrappedValue?.phone?.number ?? "")
        self._dateOfBirth = State(initialValue: user.wrappedValue?.dateOfBirth ?? Self.sixteenYearAgo)
        self._street = State(initialValue: user.wrappedValue?.address?.street ?? "")
        self._zip = State(initialValue: user.wrappedValue?.address?.zip ?? "")
        self._city = State(initialValue: user.wrappedValue?.address?.city ?? "")
        self._country = State(initialValue: user.wrappedValue?.address?.country ?? Country.germany.code)
        self._state = State(initialValue: user.wrappedValue?.address?.state ?? "")
#endif
    }
    
    func isRequired(_ field: UserField) -> Bool {
        fields.contains(field) && requiredFields.contains(field)
    }
    
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
        if isRequired(.phone), phoneNumber.isEmpty {
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
        if isRequired(.state), state.isEmpty {
            return false
        }
        return true
    }
    
    private static var sixteenYearAgo: Date {
        let sixteenYears: TimeInterval = 504_910_816
        return Date(timeIntervalSinceNow: -sixteenYears)
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    if fields.contains(.firstName) && fields.contains(.lastName) {
                        HStack {
                            UserTextFieldView(userField: .firstName, text: $firstName, disabled: $disabled)
                                .focused($focusField, equals: .firstName)
                                .onSubmit {
                                    focusField = .firstName.next(in: fields)
                                }
                            UserTextFieldView(userField: .lastName, text: $lastName, disabled: $disabled)
                                .focused($focusField, equals: .lastName)
                                .onSubmit {
                                    focusField = .lastName.next(in: fields)
                                }
                        }
                    } else if fields.contains(.lastName) {
                        UserTextFieldView(userField: .lastName, text: $lastName, disabled: $disabled)
                            .focused($focusField, equals: .lastName)
                            .onSubmit {
                                focusField = .lastName.next(in: fields)
                            }
                    }
                    if fields.contains(.email) {
                        UserTextFieldView(userField: .email, text: $email, disabled: $disabled)
                            .focused($focusField, equals: .email)
                            .onSubmit {
                                focusField = .email.next(in: fields)
                            }
                    }
                    if fields.contains(.phone) {
                        HStack {
                            CountryCallingCodeView(countries: callingCodes, selectedCountry: $callingCode)
                                .padding(12)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            UserTextFieldView(userField: .phone, text: $phoneNumber, disabled: $disabled)
                                .focused($focusField, equals: .phone)
                                .onSubmit {
                                    focusField = .phone.next(in: fields)
                                }
                        }
                    }
                    if fields.contains(.dateOfBirth) {
                        DatePicker(Asset.localizedString(forKey: UserField.dateOfBirth.prompt),
                                   selection: $dateOfBirth,
                                   in: ...Self.sixteenYearAgo,
                                   displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .focused($focusField, equals: .dateOfBirth)
                        .padding(12)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onSubmit {
                            focusField = .dateOfBirth.next(in: fields)
                        }
                        .disabled(disabled)
                    }
                }
                VStack(spacing: 8) {
                    if fields.contains(.street) {
                        UserTextFieldView(userField: .street, text: $street, disabled: $disabled)
                            .focused($focusField, equals: .street)
                            .onSubmit {
                                focusField = .street.next(in: fields)
                            }
                    }
                    if fields.contains(.zip) && fields.contains(.city) {
                        HStack {
                            UserTextFieldView(userField: .zip, text: $zip, disabled: $disabled)
                                .frame(width: 120)
                                .focused($focusField, equals: .zip)
                                .onSubmit {
                                    focusField = .zip.next(in: fields)
                                }
                            UserTextFieldView(userField: .city, text: $city, disabled: $disabled)
                                .focused($focusField, equals: .city)
                                .onSubmit {
                                    focusField = .city.next(in: fields)
                                }
                        }
                    }
                    if fields.contains(.country) || fields.contains(.state) {
                        CountryButtonView(
                            countries: Country.all,
                            selectedCountry: $countrySelection,
                            selectedState: $stateSelection
                        )
                        .onChange(of: countrySelection) {
                            country = countrySelection.code
                        }
                        .onChange(of: stateSelection) {
                            state = stateSelection?.name ?? ""
                        }
                        .focused($focusField, equals: .country)
                        .disabled(disabled)
                    }
                }
                PrimaryButtonView(
                    title: Asset.localizedString(forKey: "Snabble.UserView.next"),
                    disabled: Binding(get: { !isButtonEnabled || disabled }, set: { _ in }),
                    onAction: {
                        var user = User()
                        user.firstName = firstName.isEmpty ? nil : firstName
                        user.lastName = lastName.isEmpty ? nil : lastName
                        user.email = email.isEmpty ? nil : email
                        user.phone = phoneNumber.isEmpty ? nil : User.Phone(code: callingCode.code, number: phoneNumber)
                        user.dateOfBirth = dateOfBirth
                        
                        user.address = User.Address(street: street.isEmpty ? nil : street,
                                                    zip: zip.isEmpty ? nil : zip,
                                                    city: city.isEmpty ? nil : city,
                                                    country: country.isEmpty ? nil : country,
                                                    state: state.isEmpty ? nil : state)
                        self.user = user
                    })
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Asset.localizedString(forKey: "Snabble.UserView.title"))
    }
}
