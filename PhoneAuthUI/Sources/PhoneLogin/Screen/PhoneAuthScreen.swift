////
////  PhoneAuthScreen.swift
////  teo
////
////  Created by Andreas Osberghaus on 2024-02-07.
////
//
//import SwiftUI
//
//import SnabbleCore
//import SnabblePhoneAuth
//import SnabbleUser
//import SnabbleAssetProviding
//
////class PhoneAuthScreenViewModel {
////    let phoneAuth: PhoneAuth
////    
////    init(phoneAuth: PhoneAuth) {
////        self.phoneAuth = phoneAuth
////    }
////
////    init(configuration: SnabbleCore.Config) {
////        let phoneConfig = Configuration(appId: configuration.appId,
////                                        appSecret: configuration.secret,
////                                        domain: Domain(rawValue: configuration.environment.rawValue) ?? .production)
////        phoneAuth = PhoneAuth(configuration: phoneConfig)
////        
////        phoneAuth.delegate = self
////        phoneAuth.dataSource = self
////    }
////}
////
////extension PhoneAuthScreenViewModel: PhoneAuthDataSource {
////    func projectId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> String? {
////        nil
////    }
////    
////    func appUserId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> SnabbleUser.AppUser? {
////        AppUser.get(forConfig: configuration)
////    }
////}
////
////extension PhoneAuthScreenViewModel: PhoneAuthDelegate {
////    func phoneAuth(_ phoneAuth: SnabblePhoneAuth.PhoneAuth, didReceiveAppUser appUser: SnabbleUser.AppUser) {
////        AppUser.set(appUser, forConfig: phoneAuth.configuration)
////    }
////}
//
//public enum PhoneAuthViewKind {
//    case initial
//    case management
//}
//
//public struct PhoneAuthScreen<Header: View, Footer: View>: View {
//    @Environment(\.dismiss) var dismiss
//    
////    let viewModel: PhoneAuthScreenViewModel
//    let viewKind: PhoneAuthViewKind
//    let header: (() -> Header)?
//    let footer: (() -> Footer)?
//
//    @State var phoneNumber: String = "" {
//        didSet {
//            showOTPInput = !phoneNumber.isEmpty
//        }
//    }
//    
//    var onCompletion: ((SnabbleUser.AppUser?) -> Void)?
//    
//    @State var showProgress: Bool = false
//    @State var errorMessage: String = ""
//    
//    @State private var showOTPInput: Bool = false
//
//    public init(phoneAuth: PhoneAuth,
//                kind: PhoneAuthViewKind,
//                header: (() -> Header)?,
//                footer: (() -> Footer)?,
//                onCompletion: ((SnabbleUser.AppUser?) -> Void)? = nil
//    ) {
//        self.viewModel = PhoneAuthScreenViewModel(phoneAuth: phoneAuth)
//        self.viewKind = kind
//        self.header = header
//        self.footer = footer
//        self.onCompletion = onCompletion
//    }
//    
//    @ViewBuilder
//    var numberView: some View {
//        NumberView(
//            kind: .management,
//            header: header,
//            footer: footer
//        ) { phoneNumber in
//            print(phoneNumber)
//        }
//    }
//    
//    @ViewBuilder
//    var codeView: some View {
//        Color(.red)
////        CodeView(
////            kind: .management,
////            phoneNumber: $phoneNumber,
////            verifyCode: { code, phoneNumber in
////                sendOTP(code, phoneNumber: phoneNumber)
////            },
////            rerequestCode: { phoneNumber in
////                sendPhoneNumber(phoneNumber)
////            }
////        )
//    }
//    
//    public var body: some View {
//        numberView
////            .navigationBarTitleDisplayMode(.inline)
////            .navigationDestination(isPresented: $showOTPInput, destination: {
////                codeView
////            })
//            .environment(viewModel.phoneAuth.networkManager)
//    }
//    
//    private func startLoading() {
//        errorMessage = ""
//        showProgress = true
//    }
//    
//    private func messageFor(error: Error) -> String {
//        guard case let HTTPError.invalid(_, clientError) = error, let clientError else {
//            return Asset.localizedString(forKey: "Snabble.Account.genericError")
//        }
//        let message: String
//        switch clientError.type {
//        case "invalid_input":
//            message = "Snabble.Account.SignIn.error"
//        case "invalid_otp":
//            message = "Snabble.Account.Code.error"
//        case "validation_error":
//            if clientError.validations?.first(where: { $0.field == "phoneNumber" }) != nil {
//                message = "Snabble.Account.SignIn.error"
//            } else {
//                message = "Snabble.Account.genericError"
//            }
//        default:
//            message = "Snabble.Account.genericError"
//            
//        }
//        return Asset.localizedString(forKey: message)
//   }
//    
//    private func sendPhoneNumber(_ phoneNumber: String) {
//        Task {
//            do {
//                startLoading()
//                self.phoneNumber = try await viewModel.phoneAuth.startAuthorization(phoneNumber: phoneNumber)
//            } catch {
//                errorMessage = messageFor(error: error)
//            }
//            showProgress = false
//        }
//    }
//    
//    private func sendOTP(_ OTP: String, phoneNumber: String) {
//        Task {
//            do {
//                startLoading()
//                let appUser: AppUser?
//                switch viewKind {
//                case .initial:
//                    appUser = try await viewModel.phoneAuth.signIn(phoneNumber: phoneNumber, OTP: OTP)
//                case .management:
//                    appUser = try await viewModel.phoneAuth.changePhoneNumber(phoneNumber: phoneNumber, OTP: OTP)
//                }
//                DispatchQueue.main.sync {
//                    UserDefaults.standard.setUserSignedIn(true)
//                    onCompletion?(appUser)
//                    dismiss()
//                }
//            } catch {
//                errorMessage = messageFor(error: error)
//            }
//            showProgress = false
//        }
//    }
//}
//
//extension PhoneAuthScreen {
//    public init(phoneAuth: PhoneAuth,
//                kind: PhoneAuthViewKind,
//                onCompletion: ((SnabbleUser.AppUser?) -> Void)? = nil) where Header == Never, Footer == Never {
//        self.init(phoneAuth: phoneAuth, kind: kind, header: nil, footer: nil, onCompletion: onCompletion)
//    }
//    public init(phoneAuth: PhoneAuth,
//                kind: PhoneAuthViewKind,
//                footer: (() -> Footer)?,
//                onCompletion: ((SnabbleUser.AppUser?) -> Void)? = nil) where Header == Never {
//        self.init(phoneAuth: phoneAuth, kind: kind, header: nil, footer: footer, onCompletion: onCompletion)
//    }
//    public init(phoneAuth: PhoneAuth,
//                kind: PhoneAuthViewKind,
//                header: (() -> Header)?,
//                onCompletion: ((SnabbleUser.AppUser?) -> Void)? = nil) where Footer == Never {
//        self.init(phoneAuth: phoneAuth, kind: kind, header: header, footer: nil, onCompletion: onCompletion)
//    }
//}
