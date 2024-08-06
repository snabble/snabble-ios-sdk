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
            "Snabble.Account.SignIn.description"
        case .management:
            "Snabble.Account.ChangePhoneNumber.description"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .initial:
            "Snabble.Account.SignIn.buttonLabel"
        case .management:
            "Snabble.Account.ChangePhoneNumber.buttonLabel"
        }
    }
    
    var title: String {
        switch self {
        case .initial:
            "Snabble.Account.SignIn.title"
        case .management:
            "Snabble.Account.ChangePhoneNumber.title"
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

struct NumberView<Header: View, Footer: View>: View {
    let kind: PhoneAuthViewKind
    let countries: [SnabblePhoneAuth.Country] = SnabblePhoneAuth.Country.all
    
    @State var country: SnabblePhoneAuth.Country = .germany
    @State var number: String = ""
    
    @Binding var showProgress: Bool
    @Binding var footerMessage: String

    private let header: (() -> Header)?
    private let footer: (() -> Footer)?

    var callback: (_ phoneNumber: String) -> Void
    
    private enum Field: Hashable {
        case phoneNumber
    }
    
    @FocusState private var focusedField: Field?
    
    private var isEnabled: Bool {
        number.count > 3 && !showProgress
    }
    public init(kind: PhoneAuthViewKind,
                showProgress: Binding<Bool>,
                footerMessage: Binding<String>,
                header: (() -> Header)?,
                footer: (() -> Footer)?,
                callback: @escaping (_: String) -> Void) {
        self.kind = kind
        self._showProgress = showProgress
        self._footerMessage = footerMessage
        self.header = header
        self.footer = footer
        self.callback = callback
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    if kind == .initial {
                        if let header {
                            header()
                        } else {
                            Text(Asset.localizedString(forKey: kind.message))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(Asset.localizedString(forKey: kind.message))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom)
                .font(.callout)
                
                VStack(spacing: 16) {
                    HStack {
                        CountryCallingCodeView(countries: countries, selectedCountry: $country)
                            .padding(12)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        TextField(Asset.localizedString(forKey: "Snabble.Account.PhoneNumber.input"), text: $number)
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
                    Text(Asset.localizedString(forKey: "Snabble.Account.SignIn.hint"))
                    if !footerMessage.isEmpty {
                        Text(footerMessage)
                            .foregroundColor(.red)
                    }
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
                
                if kind == .management {
                    if let footer {
                        footer()
                    }
                }
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

extension NumberView {
    public init(kind: PhoneAuthViewKind, 
                showProgress: Binding<Bool>,
                footerMessage: Binding<String>,
                callback: @escaping (_: String) -> Void) where Footer == Never, Header == Never {
        self.init(kind: kind,
                  showProgress: showProgress,
                  footerMessage: footerMessage,
                  header: nil,
                  footer: nil,
                  callback: callback)
    }
    public init(kind: PhoneAuthViewKind,
                showProgress: Binding<Bool>,
                footerMessage: Binding<String>,
                header: (() -> Header)?,
                callback: @escaping (_: String) -> Void) where Footer == Never {
        self.init(kind: kind,
                  showProgress: showProgress,
                  footerMessage: footerMessage,
                  header: header,
                  footer: nil,
                  callback: callback)
    }
    public init(kind: PhoneAuthViewKind,
                showProgress: Binding<Bool>,
                footerMessage: Binding<String>,
                footer: (() -> Footer)?,
                callback: @escaping (_: String) -> Void) where Header == Never {
        self.init(kind: kind,
                  showProgress: showProgress,
                  footerMessage: footerMessage,
                  header: nil,
                  footer: footer,
                  callback: callback)
    }
}
