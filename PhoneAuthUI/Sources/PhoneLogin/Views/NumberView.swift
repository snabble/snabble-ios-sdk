//
//  NumberView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import SnabblePhoneAuth
import SnabbleAssetProviding
import Combine
import SnabbleNetwork

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
    var networkManager: NetworkManager? = nil
    let kind: PhoneAuthViewKind
    let countries: [CallingCode] = CallingCode.all
    
    @State var country: CallingCode = .germany
    @State var number: String = ""
    
    @State var showProgress: Bool = false
    @State var footerMessage: String = ""

    private let header: (() -> Header)?
    private let footer: (() -> Footer)?

    var callback: (_ phoneNumber: String?) -> Void
    
    private enum Field: Hashable {
        case phoneNumber
    }
    
    @FocusState private var focusedField: Field?
    
    private var isEnabled: Bool {
        number.count > 3 && !showProgress
    }
    
    public init(kind: PhoneAuthViewKind,
                header: (() -> Header)?,
                footer: (() -> Footer)?,
                callback: @escaping (_: String?) -> Void) {
        self.kind = kind
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
        Task {
            let phoneNumber = try? await startAuthorization(phoneNumber: "+\(country.callingCode)\(number)")
            callback(phoneNumber)
        }
        
    }
    
    private func useContinuation<Value, Response>(endpoint: Endpoint<Response>, receiveValue: @escaping (Response, CheckedContinuation<Value, any Error>) -> Void) async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = networkManager!.publisher(for: endpoint)
                .mapHTTPErrorIfPossible()
                .receive(on: RunLoop.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()

                } receiveValue: { response in
                    receiveValue(response, continuation)
                }
        }
    }
    
    private func startAuthorization(phoneNumber: String) async throws -> String {
        let endpoint = Endpoints.Phone.auth(
            phoneNumber: phoneNumber
        )

        return try await useContinuation(endpoint: endpoint) { _, continuation in
            continuation.resume(with: .success(phoneNumber))
        }
    }
}

extension NumberView {
    public init(kind: PhoneAuthViewKind,
                callback: @escaping (_: String?) -> Void) where Footer == Never, Header == Never {
        self.init(kind: kind,
                  header: nil,
                  footer: nil,
                  callback: callback)
    }
    public init(kind: PhoneAuthViewKind,
                header: (() -> Header)?,
                callback: @escaping (_: String?) -> Void) where Footer == Never {
        self.init(kind: kind,
                  header: header,
                  footer: nil,
                  callback: callback)
    }
    public init(kind: PhoneAuthViewKind,
                footer: (() -> Footer)?,
                callback: @escaping (_: String?) -> Void) where Header == Never {
        self.init(kind: kind,
                  header: nil,
                  footer: footer,
                  callback: callback)
    }
}
