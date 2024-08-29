//
//  CodeView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUser
import SnabbleNetwork

extension CodeViewKind {
    var codeButtonTitle: String {
        switch self {
        case .initial:
            "Snabble.Account.Code.buttonLabel"
        case .management:
            "Snabble.Account.UserDetails.Change.buttonLabel"
        }
    }
}

public enum CodeViewKind {
    case initial
    case management
}

public struct CodeView: View {
    @SwiftUI.Environment(NetworkManager.self) var networkManager
    
    public init(kind: CodeViewKind, phoneNumber: String, onCompletion: @escaping (_: AppUser?) -> Void) {
        self.kind = kind
        self.phoneNumber = phoneNumber
        self.onCompletion = onCompletion
    }
    
    public let kind: CodeViewKind
    public let phoneNumber: String
    
    @State var otp: String = ""
    
    @State var showProgress: Bool = false
    @State var errorMessage: String = ""
    
    public var onCompletion: (_ appUser: AppUser?) -> Void
    
    private var isEnabled: Bool {
        otp.count == 6
    }
    
    private enum Field: Hashable {
        case code
    }
    
    @FocusState private var focusedField: Field?
    
    public var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 24) {
                Text(Asset.localizedString(forKey: "Snabble.Account.Code.description", arguments: phoneNumber))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                TextField(Asset.localizedString(forKey: "Snabble.Account.Code.input"), text: $otp)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .code)
                    .disabled(showProgress)
                    .submitLabel(.done)
                    .padding(12)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit {
                        if isEnabled {
                            verifyCode(otp, phoneNumber: phoneNumber)
                        }
                    }
            }
            
            ProgressButtonView(
                title: Asset.localizedString(forKey: kind.codeButtonTitle),
                showProgress: $showProgress,
                action: {
                    verifyCode(otp, phoneNumber: phoneNumber)
                })
            .buttonStyle(AccentButtonStyle(disabled: !isEnabled))
            .disabled(!isEnabled)
            
            LockedButtonView(
                title: Asset.localizedString(forKey: "Snabble.Account.Code.requestNewCode"),
                action: {
                    resendPhoneNumber(phoneNumber)
                })
            
            Text(errorMessage)
                .font(.footnote)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .onAppear {
            focusedField = .code
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Account.Code.title"))
    }
    
    private func useContinuation<Value, Response>(endpoint: Endpoint<Response>, receiveValue: @escaping (Response, CheckedContinuation<Value, any Error>) -> Void) async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = networkManager.publisher(for: endpoint)
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
    
    @discardableResult
    private func startAuthorization(phoneNumber: String) async throws -> String {
        let endpoint = Endpoints.Phone.auth(
            phoneNumber: phoneNumber
        )

        return try await useContinuation(endpoint: endpoint) { _, continuation in
            continuation.resume(with: .success(phoneNumber))
        }
    }
    
    private func signIn(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser? {
        let endpoint = Endpoints.Phone.signIn(
            phoneNumber: phoneNumber,
            OTP: OTP
        )

        return try await useContinuation(endpoint: endpoint) { response, continuation in
            continuation.resume(with: .success(response))
        }
    }
    
    private func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser? {
        let endpoint = Endpoints.Phone.changePhoneNumber(
            phoneNumber: phoneNumber,
            OTP: OTP
        )

        return try await useContinuation(endpoint: endpoint) { response, continuation in
            continuation.resume(with: .success(response))
        }
    }
    
    private func resendPhoneNumber(_ phoneNumber: String) {
        Task {
            do {
                showProgress = true
                try await startAuthorization(phoneNumber: phoneNumber)
            } catch {
                errorMessage = messageFor(error: error)
            }
            showProgress = false
        }
        
    }
    
    private func verifyCode(_ OTP: String, phoneNumber: String) {
        Task {
            do {
                showProgress = true
                let appUser: AppUser?
                switch kind {
                case .initial:
                    appUser = try await signIn(phoneNumber: phoneNumber, OTP: OTP)
                case .management:
                    appUser = try await changePhoneNumber(phoneNumber: phoneNumber, OTP: OTP)
                }
                onCompletion(appUser)
                DispatchQueue.main.sync {
//                    UserDefaults.standard.setUserSignedIn(true)
                    
                }
            } catch {
                errorMessage = messageFor(error: error)
            }
            showProgress = false
        }
    }
    
    private func messageFor(error: Error) -> String {
        guard case let HTTPError.invalid(_, clientError) = error, let clientError else {
            return Asset.localizedString(forKey: "Snabble.Account.genericError")
        }
        let message: String
        switch clientError.type {
        case "invalid_otp":
            message = "Snabble.Account.Code.error"
        case "validation_error":
            message = "Snabble.Account.SignIn.error"
        default:
            message = "Snabble.Account.genericError"
            
        }
        return Asset.localizedString(forKey: message)
   }
}
