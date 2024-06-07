//
//  NumberView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import SnabblePhoneAuth
import SnabbleAssetProviding

private extension PhoneAuthViewKind {
    var message: String {
        switch self {
        case .initial:
            "Account.SignIn.description"
        case .management:
            "Account.ChangePhoneNumber.description"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .initial:
            "Account.SignIn.buttonLabel"
        case .management:
            "Account.ChangePhoneNumber.buttonLabel"
        }
    }
    
    var title: String {
        switch self {
        case .initial:
            "Account.SignIn.title"
        case .management:
            "Account.ChangePhoneNumber.title"
        }
    }
}

private struct LabelWithImageAccent: View {
    /// The title which will be passed to the title attribute of the Label View.
    let title: String
    /// The name of the image to pass into the Label View.
    let systemName: String
    
    var body: some View {
        Label(title: {
            Text(title)
        }, icon: {
            Image(systemName: systemName)
                .foregroundStyle(Color.accent())
        })
    }
}

struct NumberView: View {
    let kind: PhoneAuthViewKind
    let countries: [SnabblePhoneAuth.Country] = SnabblePhoneAuth.Country.all
    @ViewProvider(.phoneBenefits) var phoneBenefits

    @State var country: SnabblePhoneAuth.Country = .germany
    @State var number: String = ""
    
    @Binding var showProgress: Bool
    @Binding var footerMessage: String
    
    var callback: (_ phoneNumber: String) -> Void
    
    private enum Field: Hashable {
        case phoneNumber
    }
    
    @FocusState private var focusedField: Field?
    
    private var isEnabled: Bool {
        number.count > 3 && !showProgress
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    if kind == .initial {
                        phoneBenefits
                    }
                    Text(Asset.localizedString(forKey: kind.message))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom)
                .font(.callout)
                
                VStack(spacing: 16) {
                    HStack {
                        CountryCallingCodeView(countries: countries, selectedCountry: $country)
                            .padding(12)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        TextField(Asset.localizedString(forKey: "PhoneNumber.input"), text: $number)
                            .keyboardType(.phonePad)
                            .focused($focusedField, equals: .phoneNumber)
                            .submitLabel(.continue)
                            .padding(12)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onSubmit {
                                submit()
                            }
                    }
                    .disabled(showProgress)
                    
                    ProgressButtonView(
                        title: Asset.localizedString(forKey: kind.buttonTitle),
                        showProgress: $showProgress,
                        action: {
                            submit()
                        })
                    .buttonStyle(AccentButtonStyle(disabled: !isEnabled))
                    .disabled(!isEnabled)
                }
                
                VStack(spacing: 8) {
                    Text(Asset.localizedString(forKey: "Account.SignIn.hint"))
                    if !footerMessage.isEmpty {
                        Text(footerMessage)
                            .foregroundColor(.red)
                    }
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
                
                Spacer(minLength: 0)
            }
            .padding([.top, .leading, .trailing])
            .onAppear {
                focusedField = .phoneNumber
            }
        }
        .navigationTitle(Asset.localizedString(forKey: kind.title))
    }
    
    private func submit() {
        callback("+\(country.callingCode)\(number)")
    }
}
