//
//  PhoneAuthScreen.swift
//  PhoneAuthScreen
//
//  Created by Uwe Tilemann on 17.01.23.
//

import SwiftUI
import SnabblePhoneAuth

class PhoneAuthScreenViewModel {
    let phoneAuth: PhoneAuth
    
    private(set) var appUser: AppUser?
    
    init(configuration: Configuration) {
        phoneAuth = PhoneAuth(configuration: configuration)
        
        phoneAuth.delegate = self
        phoneAuth.dataSource = self
    }
}

extension PhoneAuthScreenViewModel: PhoneAuthDataSource {
    func projectId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> String? {
        Configuration.projectId
    }
    
    func appUserId(forConfiguration configuration: SnabblePhoneAuth.Configuration) -> SnabblePhoneAuth.AppUser? {
        appUser
    }
}

extension PhoneAuthScreenViewModel: PhoneAuthDelegate {
    func phoneAuth(_ phoneAuth: SnabblePhoneAuth.PhoneAuth, didReceiveAppUser appUser: SnabblePhoneAuth.AppUser) {
        self.appUser = appUser
    }
}

struct PhoneAuthScreen: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: PhoneAuthScreenViewModel
    
    @State private var showingAlert = false
    @State var appUser: AppUser?
    
    @State var phoneNumber: String = "" {
        didSet {
            showOTPInput = !phoneNumber.isEmpty
        }
    }
    
    @State var showProgress: Bool = false
    @State var errorMessage: String = ""
    
    @State private var showOTPInput: Bool = false
    
    init(configuration: Configuration) {
        viewModel = PhoneAuthScreenViewModel(
            configuration: configuration
        )
    }
    
    @ViewBuilder
    var numberView: some View {
        NumberView(
            showProgress: $showProgress,
            footerMessage: $errorMessage
        ) { phoneNumber in
            sendPhoneNumber(phoneNumber)
        }
    }
    
    @ViewBuilder
    var codeView: some View {
        CodeView(
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
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text("Logged in successfully"))
        }
    }
    
    private func startLoading() {
        errorMessage = ""
        showProgress = true
    }
    
    private func sendPhoneNumber(_ phoneNumber: String) {
        Task {
            do {
                startLoading()
                self.phoneNumber = try await viewModel.phoneAuth.startAuthorization(
                    phoneNumber: phoneNumber
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            showProgress = false
        }
    }
    
    private func sendOTP(_ OTP: String, phoneNumber: String) {
        Task {
            do {
                startLoading()
                appUser = try await viewModel.phoneAuth.signIn(phoneNumber: phoneNumber, OTP: OTP)
                showingAlert = true
                
                DispatchQueue.main.sync {
                    dismiss()
                }
            } catch {
                if case let HTTPError.invalid(_, clientError) = error {
                    if let clientError = clientError {
                        errorMessage = clientError.message
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            showProgress = false
        }
    }
}
