//
//  PhoneAuthScreen.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import SnabblePhoneAuth
import Defaults

private extension AppUserId {
    func toAppUser() -> SnabblePhoneAuth.AppUser {
        SnabblePhoneAuth.AppUser(id: value, secret: secret)
    }
}

private extension SnabblePhoneAuth.AppUser {
    func toAppUserId() -> AppUserId {
        AppUserId(value: id, secret: secret)
    }
}

class PhoneAuthScreenViewModel {
    let phoneAuth: PhoneAuth
    
    init(configuration: SnabbleCore.Config) {
        phoneAuth = PhoneAuth(
            configuration: Configuration.configuration(
                from: configuration)
        )
        phoneAuth.delegate = self
        phoneAuth.dataSource = self
    }
}

extension PhoneAuthScreenViewModel: PhoneAuthDataSource {
    func projectId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> String? {
        Snabble.shared.projects.first?.id.rawValue
    }
    
    func appUserId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> SnabblePhoneAuth.AppUser? {
        Snabble.shared.appUserId?.toAppUser()
    }
}

extension PhoneAuthScreenViewModel: PhoneAuthDelegate {
    func phoneAuth(_ phoneAuth: SnabblePhoneAuth.PhoneAuth, didReceiveAppUser appUser: SnabblePhoneAuth.AppUser) {
        Snabble.shared.appUserId = appUser.toAppUserId()
    }
}

enum PhoneAuthViewKind {
    case initial
    case management
}

struct PhoneAuthScreen: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: PhoneAuthScreenViewModel
    let viewKind: PhoneAuthViewKind
    
    @State var phoneNumber: String = "" {
        didSet {
            showOTPInput = !phoneNumber.isEmpty
        }
    }
    
    var onCompletion: ((SnabblePhoneAuth.AppUser?) -> Void)?
    
    @State var showProgress: Bool = false
    @State var errorMessage: String = ""
    
    @State private var showOTPInput: Bool = false
    
    init(configuration: SnabbleCore.Config, kind: PhoneAuthViewKind, onCompletion: ((SnabblePhoneAuth.AppUser?) -> Void)? = nil) {
        self.viewModel = PhoneAuthScreenViewModel(configuration: configuration)
        self.viewKind = kind
        self.onCompletion = onCompletion
    }
    
    @ViewBuilder
    var numberView: some View {
        NumberView(
            kind: viewKind,
            showProgress: $showProgress,
            footerMessage: $errorMessage
        ) { phoneNumber in
            sendPhoneNumber(phoneNumber)
        }
    }
    
    @ViewBuilder
    var codeView: some View {
        CodeView(
            kind: viewKind,
            phoneNumber: $phoneNumber,
            showProgress: $showProgress,
            footerMessage: $errorMessage,
            verifyCode: { code, phoneNumber in
                sendOTP(code, phoneNumber: phoneNumber)
            },
            rerequestCode: { phoneNumber in
                sendPhoneNumber(phoneNumber)
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            numberView
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showOTPInput, destination: {
                codeView
            })
        }
    }
    
    private func startLoading() {
        errorMessage = ""
        showProgress = true
    }
    
    private func messageFor(error: Error) -> String {
        guard case let HTTPError.invalid(_, clientError) = error, let clientError else {
            return Asset.localizedString(forKey: "Account.genericError")
        }
        let message: String
        switch clientError.type {
        case "invalid_input":
            message = "Account.SignIn.error"
        case "invalid_otp":
            message = "Account.Code.error"
        default:
            message = "Account.genericError"
        }
        return Asset.localizedString(forKey: message)
   }
    
    private func sendPhoneNumber(_ phoneNumber: String) {
        Task {
            do {
                startLoading()
                self.phoneNumber = try await viewModel.phoneAuth.startAuthorization(
                    phoneNumber: phoneNumber
                )
            } catch {
                errorMessage = messageFor(error: error)
            }
            showProgress = false
        }
    }
    
    private func sendOTP(_ OTP: String, phoneNumber: String) {
        Task {
            do {
                startLoading()
                let appUser: AppUser?
                switch viewKind {
                case .initial:
                    appUser = try await viewModel.phoneAuth.signIn(phoneNumber: phoneNumber, OTP: OTP)
                case .management:
                    appUser = try await viewModel.phoneAuth.changePhoneNumber(phoneNumber: phoneNumber, OTP: OTP)
                }
                DispatchQueue.main.sync {
                    Defaults[.isSignedIn] = true
                    onCompletion?(appUser)
                    dismiss()
                }
            } catch {
                errorMessage = messageFor(error: error)
            }
            showProgress = false
        }
    }
}
