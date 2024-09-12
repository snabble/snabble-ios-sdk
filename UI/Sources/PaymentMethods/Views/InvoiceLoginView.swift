//
//  InvoiceLoginView.swift
//  
//
//  Created by Uwe Tilemann on 02.06.23.
//

import Foundation
import SwiftUI
import UIKit
import SnabbleAssetProviding

extension InvoiceLoginModel {
    public var image: SwiftUI.Image? {
        guard let imageName = imageName, let uiImage: UIImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

public struct InvoiceLoginView: View {
    @ObservedObject var model: InvoiceLoginProcessor
    @StateObject private var loginModel: InvoiceLoginModel

    @State private var canLogin = false
    @State private var username = ""
    @State private var password = ""

    @Environment(\.presentationMode) var presentationMode

    let domain = "Snabble.Payment.ExternalBilling"
    
    public init(model: InvoiceLoginProcessor) {
        self.model = model
        self._loginModel = StateObject(wrappedValue: model.invoiceLoginModel)
    }

    @ViewBuilder
    var button: some View {
        Button(action: {
            login()
        }) {
            HStack {
                Text(keyed: "Snabble.PaymentMethods.add")
                if model.isWaiting {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canLogin)
        .opacity(!canLogin ? 0.5 : 1.0)
    }
    
    private func login() {
        guard loginModel.isValid else {
            return
        }
        hideKeyboard()
        loginModel.actionPublisher.send(["action": LoginViewModel.Action.login.rawValue])
    }
    
    @ViewBuilder
    var footerView: some View {
        if let message = loginModel.errorMessage {
            Label(message, systemImage: "xmark.circle.fill")
                .font(.footnote)
                .foregroundColor(.red)
        }
    }

    public var body: some View {
        Form {
            Section(
                content: {
                    TextField(LoginStrings.username.localizedString(domain), text: $username)
                        .keyboardType(.emailAddress)
                    SecureField(LoginStrings.password.localizedString(domain), text: $password) {
                        login()
                    }
                    .keyboardType(.default)
                },
                header: {
                    Text(LoginStrings.info.localizedString(domain))
                }
            )
            .textCase(nil)
            Section(
                content: {
                    button
                },
                footer: {
                    footerView
                })
        }
        .onChange(of: username) { _, string in
            loginModel.username = string
        }
        .onChange(of: password) { _, string in
            loginModel.password = string
        }
        .onChange(of: loginModel.isValid) { _, isValid in
            if model.isWaiting {
                canLogin = false
            } else {
                canLogin = isValid
            }
        }
    }
}

public struct InvoiceDetailView: View {
    @ObservedObject private var loginModel: InvoiceLoginModel
    @Environment(\.presentationMode) var presentationMode
    let domain = "Snabble.Payment.ExternalBilling"

    public init(model: InvoiceLoginModel) {
        self.loginModel = model
    }
        
    public var body: some View {
        Form {
            Section(
                content: {
                    HStack {
                        if let image = loginModel.image {
                            image
                        }
                        Text(loginModel.username ?? "")
                    }
                },
                header: {
                    Text(LoginStrings.username.localizedString(domain))
                },
                footer: {
                    Text(keyed: "Snabble.Payment.ExternalBilling.hint")
                })
            .textCase(nil)
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(action: {
                    loginModel.actionPublisher.send(["action": LoginViewModel.Action.remove.rawValue])
                }) {
                    Image(systemName: "trash")
                }
                .foregroundColor(Color.projectPrimary())
            }
        }
    }
}

public struct InvoiceView: View {
    @ObservedObject var loginProcessor: InvoiceLoginProcessor
    @StateObject private var loginModel: InvoiceLoginModel
    
    init(model: InvoiceLoginProcessor) {
        self.loginProcessor = model
        self._loginModel = StateObject(wrappedValue: model.invoiceLoginModel)

    }
    @ViewBuilder
    var content: some View {
        if loginModel.paymentUsername != nil || loginModel.isLoggedIn {
            InvoiceDetailView(model: loginModel)
        } else {
            InvoiceLoginView(model: self.loginProcessor)
        }
    }

    public var body: some View {
        content
            .onChange(of: loginModel.isLoggedIn) { _, loggedIn in
                if loggedIn, loginModel.loginInfo != nil {
                    loginModel.actionPublisher.send(["action": LoginViewModel.Action.save.rawValue])
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title"))
    }
}
