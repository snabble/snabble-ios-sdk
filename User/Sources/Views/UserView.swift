//
//  SwiftUIView.swift
//  
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI
import SnabbleAssetProviding

extension UserField {
    public func next(in array: [UserField]) -> UserField? {
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

struct UserTextFieldView: View {
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
    @ObservedObject var model: UserModel
    
#if DEBUG
    @State private var firstName: String = "Foo"
    @State private var lastName: String = "Bar"
    @State private var email: String = "foo@bar.com"
    @State private var phoneNumber: String = "177 8765432"
    @State private var dateOfBirth: Date
    @State private var street: String = "Mainroad 55"
    @State private var zip: String = "12345"
    @State private var city: String = "Jupiter"
    @State private var country: String = ""
    @State private var state: String = ""
#else
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
#endif
    @State private var countrySelection: Country = Country.germany
    @State private var stateSelection: Country.State?

    let callingCodes: [CallingCode] = CallingCode.all
    @State var callingCode: CallingCode = CallingCode.germany

    @State private var disabled: Bool = false
    
    @FocusState private var focusField: UserField?
    
    public init(model: UserModel) {
        self.model = model
        
        self._dateOfBirth = State(initialValue: Self.sixteenYearAgo)
        self._country = State(initialValue: Country.germany.code)
    }
    
    func isRequired(_ field: UserField) -> Bool {
        model.fields.contains(field) && model.required.contains(field)
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
        if isRequired(.phone), email.isEmpty {
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
                    if model.fields.contains(.firstName) && model.fields.contains(.lastName) {
                        HStack {
                            UserTextFieldView(userField: .firstName, text: $firstName, disabled: $disabled)
                                .focused($focusField, equals: .firstName)
                                .onSubmit {
                                    focusField = .firstName.next(in: model.fields)
                                }
                            UserTextFieldView(userField: .lastName, text: $lastName, disabled: $disabled)
                                .focused($focusField, equals: .lastName)
                                .onSubmit {
                                    focusField = .lastName.next(in: model.fields)
                                }
                        }
                    } else if model.fields.contains(.lastName) {
                        UserTextFieldView(userField: .lastName, text: $lastName, disabled: $disabled)
                            .focused($focusField, equals: .lastName)
                            .onSubmit {
                                focusField = .lastName.next(in: model.fields)
                            }
                    }
                    if model.fields.contains(.email) {
                        UserTextFieldView(userField: .email, text: $email, disabled: $disabled)
                            .focused($focusField, equals: .email)
                            .onSubmit {
                                focusField = .email.next(in: model.fields)
                            }
                    }
                    if model.fields.contains(.phone) {
                        HStack {
                            CountryCallingCodeView(countries: callingCodes, selectedCountry: $callingCode)
                                .padding(12)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            UserTextFieldView(userField: .phone, text: $phoneNumber, disabled: $disabled)
                                .focused($focusField, equals: .phone)
                                .onSubmit {
                                    focusField = .phone.next(in: model.fields)
                                }
                        }
                    }
                    if model.fields.contains(.dateOfBirth) {
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
                            focusField = .dateOfBirth.next(in: model.fields)
                        }
                        .disabled(disabled)
                    }
                }
                VStack(spacing: 8) {
                    if model.fields.contains(.street) {
                        UserTextFieldView(userField: .street, text: $street, disabled: $disabled)
                            .focused($focusField, equals: .street)
                            .onSubmit {
                                focusField = .street.next(in: model.fields)
                            }
                    }
                    if model.fields.contains(.zip) && model.fields.contains(.city) {
                        HStack {
                            UserTextFieldView(userField: .zip, text: $zip, disabled: $disabled)
                                .frame(width: 120)
                                .focused($focusField, equals: .zip)
                                .onSubmit {
                                    focusField = .zip.next(in: model.fields)
                                }
                            UserTextFieldView(userField: .city, text: $city, disabled: $disabled)
                                .focused($focusField, equals: .city)
                                .onSubmit {
                                    focusField = .city.next(in: model.fields)
                                }
                        }
                    }
                    if model.fields.contains(.country) || model.fields.contains(.state) {
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
                        let userPhone = User.Phone(code: callingCode.callingCode, number: phoneNumber)
                        
                        var user = User()
                        user.firstName = isRequired(.firstName) ? firstName : nil
                        user.lastName = isRequired(.lastName) ? lastName : nil
                        user.email = isRequired(.email) ? email : nil
                        user.phone = isRequired(.phone) ? userPhone : nil
                        user.dateOfBirth = isRequired(.dateOfBirth) ? dateOfBirth : nil
                        
                        user.address = User.Address(street: isRequired(.street) ? street : nil,
                                                    zip: isRequired(.zip) ? zip : nil,
                                                    city: isRequired(.city) ? city : nil,
                                                    country: isRequired(.country) ? country : nil,
                                                    state: isRequired(.state) && !state.isEmpty ? state : nil)
                        self.model.user = user
                    })
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Asset.localizedString(forKey: "Snabble.UserView.title"))
    }
}
