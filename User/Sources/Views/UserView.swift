//
//  SwiftUIView.swift
//  
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI

import SnabbleAssetProviding
// import SnabblePhoneAuthUI

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
        TextField(userField.prompt, text: $text)
            .textContentType(userField.contentType)
            .keyboardType(userField.keyboardType)
            .submitLabel(.continue)
            .padding(12)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .disabled(disabled)
    }
}

struct UserView: View {
    var fields: [UserField]
    let required: [UserField]
    
    let onAction: (User) -> Void
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var dateOfBirth: Date
    @State private var street: String = ""
    @State private var zip: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var state: String = ""
    
    @State private var countrySelection: Country = Country.germany
    @State private var stateSelection: Country.State?

    @State private var disabled: Bool = false
    
    @FocusState private var focusField: UserField?
    
    init(user: User = .init(),
         fields: [UserField] = UserField.allCases,
         required: [UserField] = UserField.allCases,
         onAction: @escaping (_: User) -> Void) {
        self.fields = fields
        self.required = required
        self.onAction = onAction
        self._dateOfBirth = State(initialValue: Self.sixteenYearAgo)
   }
    
    func isRequired(_ field: UserField) -> Bool {
        fields.contains(field) && required.contains(field)
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

    var body: some View {
        NavigationView {
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
                            UserTextFieldView(userField: .phone, text: $phone, disabled: $disabled)
                                .focused($focusField, equals: .phone)
                                .onSubmit {
                                    focusField = .phone.next(in: fields)
                                }
                        }
                        if fields.contains(.dateOfBirth) {
                            DatePicker(UserField.dateOfBirth.prompt,
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
                        if fields.contains(.country) {
                            UserTextFieldView(userField: .country, text: $country, disabled: $disabled)
                                .focused($focusField, equals: .country)
                                .onSubmit {
                                    focusField = .country.next(in: fields)
                                }
                            
                                            CountryButtonView(
                                                countries: Country.all,
                                                selectedCountry: $countrySelection,
                                                selectedState: $stateSelection
                                            )
                                            .focused($focusField, equals: .country)
                                            .disabled(disabled)
                        }
                        if fields.contains(.state) {
                            UserTextFieldView(userField: .state, text: $country, disabled: $disabled)
                                .focused($focusField, equals: .state)
                                .onSubmit {
                                    focusField = .state.next(in: fields)
                                }
                        }
                    }
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            let user = User(firstname: firstName,
//                                            lastname: lastName,
//                                            email: email,
//                                            phone: phone,
//                                            street: street,
//                                            zip: zip,
//                                            city: city,
//                                            country: country,
//                                            state: state)
//                            onAction(user)
//                        }) {
//                            Text("Weiter")
//                        }
//                        .disabled(!isButtonEnabled || disabled)
//                        Spacer()
//                    }
                    PrimaryButtonView(
                        title: Asset.localizedString(forKey: "Snabble.UserView.next"),
                        disabled: Binding(get: { !isButtonEnabled || disabled }, set: { _ in }),
                        onAction: {
                            let user = User(firstname: firstName,
                                            lastname: lastName,
                                            email: email,
                                            phone: phone,
                                            street: street,
                                            zip: zip,
                                            city: city,
                                            country: country,
                                            state: state)
                            onAction(user)
                        })
                }
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Asset.localizedString(forKey: "Snabble.UserView.title"))
        }
    }
}

#Preview {
    UserView { user in
        print("User:", user)
    }
}
