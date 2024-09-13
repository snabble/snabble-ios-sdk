//
//  CodeView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import Combine

import SnabbleAssetProviding
import SnabbleUser
import SnabbleNetwork
import SnabbleComponents

private extension PhoneAuthKind {
    var codeButtonTitle: String {
        switch self {
        case .initial:
            "Snabble.Account.Code.buttonLabel"
        case .management:
            "Snabble.Account.UserDetails.Change.buttonLabel"
        }
    }
}

public struct CodeView: View {
    @SwiftUI.Environment(NetworkManager.self) var networkManager
    
    public init(kind: PhoneAuthKind, phoneNumber: String, onCompletion: @escaping (_: AppUser?) -> Void) {
        self.kind = kind
        self.phoneNumber = phoneNumber
        self.onCompletion = onCompletion
    }
    
    public let kind: PhoneAuthKind
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
            .buttonStyle(ProjectPrimaryButtonStyle(disabled: !isEnabled))
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
    
    private func resendPhoneNumber(_ phoneNumber: String) {
        Task {
            do {
                showProgress = true
                try await networkManager.startAuthorization(phoneNumber: phoneNumber)
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
                    appUser = try await networkManager.signIn(phoneNumber: phoneNumber, OTP: OTP)
                case .management:
                    appUser = try await networkManager.changePhoneNumber(phoneNumber: phoneNumber, OTP: OTP)
                }
                DispatchQueue.main.async {
                    onCompletion(appUser)
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
        case "invalid_input":
            message = "Snabble.Account.SignIn.error"
        case "invalid_otp":
            message = "Snabble.Account.Code.error"
        case "validation_error":
            if clientError.validations?.first(where: { $0.field == "phoneNumber" }) != nil {
                message = "Snabble.Account.SignIn.error"
            } else {
                message = "Snabble.Account.genericError"
            }
        default:
            message = "Snabble.Account.genericError"
            
        }
        return Asset.localizedString(forKey: message)
   }
}
