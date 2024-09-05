//
//  NumberView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import Combine

import SnabbleNetwork
import SnabbleAssetProviding

private extension PhoneAuthKind {
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

public struct NumberView<Header: View, Footer: View>: View {
    @SwiftUI.Environment(NetworkManager.self) var networkManager: NetworkManager
    
    let kind: PhoneAuthKind
    let countries: [CallingCode] = CallingCode.all
    
    @State var country: CallingCode = .germany
    @State var number: String = ""
    
    @State var showProgress: Bool = false
    @State var errorMessage: String = ""

    private let header: (() -> Header)?
    private let footer: (() -> Footer)?

    var onCompetion: (_ phoneNumber: String?) -> Void
    
    private enum Field: Hashable {
        case phoneNumber
    }
    
    @FocusState private var focusedField: Field?
    
    private var isEnabled: Bool {
        number.count > 3 && !showProgress
    }
    
    public init(kind: PhoneAuthKind = .initial,
                header: (() -> Header)?,
                footer: (() -> Footer)?,
                onCompetion: @escaping (_: String?) -> Void) {
        self.kind = kind
        self.header = header
        self.footer = footer
        self.onCompetion = onCompetion
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    if let header {
                        header()
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
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
                
                if let footer {
                    footer()
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
    
    private func messageFor(error: Swift.Error) -> String {
        guard case let SnabbleNetwork.HTTPError.invalid(_, clientError) = error, let clientError else {
            return Asset.localizedString(forKey: "Snabble.Account.genericError")
        }
        let message: String
        switch clientError.type {
        case "validation_error":
            message = "Snabble.Account.SignIn.error"
        default:
            message = "Snabble.Account.genericError"
            
        }
        return Asset.localizedString(forKey: message)
   }
    
    private func submit() {
        Task {
            do {
                showProgress = true
                let phoneNumber = try await networkManager.startAuthorization(phoneNumber: "+\(country.code)\(number)")
                onCompetion(phoneNumber)
            } catch {
                errorMessage = messageFor(error: error)
            }
            showProgress = false
        }
        
    }
}

extension NumberView {
    public init(kind: PhoneAuthKind = .initial,
                onCompetion: @escaping (_: String?) -> Void) where Footer == Never, Header == Never {
        self.init(kind: kind,
                  header: nil,
                  footer: nil,
                  onCompetion: onCompetion)
    }
    public init(kind: PhoneAuthKind = .initial,
                header: (() -> Header)?,
                onCompetion: @escaping (_: String?) -> Void) where Footer == Never {
        self.init(kind: kind,
                  header: header,
                  footer: nil,
                  onCompetion: onCompetion)
    }
    public init(kind: PhoneAuthKind = .initial,
                footer: (() -> Footer)?,
                onCompetion: @escaping (_: String?) -> Void) where Header == Never {
        self.init(kind: kind,
                  header: nil,
                  footer: footer,
                  onCompetion: onCompetion)
    }
}
