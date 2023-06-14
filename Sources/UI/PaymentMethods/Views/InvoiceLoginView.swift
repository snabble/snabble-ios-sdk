//
//  InvoiceLoginView.swift
//  
//
//  Created by Uwe Tilemann on 02.06.23.
//

import Foundation
import SwiftUI
import UIKit

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
    
    @State private var canLogin = false
    @State private var errorMessage = ""
    
    @Environment(\.presentationMode) var presentationMode

    let domain = "Snabble.Payment.ExternalBilling"
    
    public init(model: InvoiceLoginProcessor) {
        self.model = model
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
        .buttonStyle(AccentButtonStyle())
        .disabled(!canLogin)
        .opacity(!canLogin ? 0.5 : 1.0)
    }
    
    private func login() {
        guard model.invoiceLoginModel.isValid else {
            return
        }
        hideKeyboard()
        model.invoiceLoginModel.actionPublisher.send(["action": LoginViewModel.Action.login.rawValue])
    }
    
    @ViewBuilder
    var footerView: some View {
        if !model.invoiceLoginModel.errorMessage.isEmpty /* !errorMessage.isEmpty*/ {
            Label(model.invoiceLoginModel.errorMessage, systemImage: "xmark.circle.fill")
                .font(.footnote)
                .foregroundColor(.red)
        }
    }

    public var body: some View {
        Form {
            Section(
                content: {
                    TextField(LoginStrings.username.localizedString(domain), text:  $model.invoiceLoginModel.username)
                        .keyboardType(.emailAddress)
                    SecureField(LoginStrings.password.localizedString(domain), text:  $model.invoiceLoginModel.password) {
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
                    if !model.invoiceLoginModel.errorMessage.isEmpty {
                        Label( model.invoiceLoginModel.errorMessage, systemImage: "xmark.circle.fill")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                } )
        }
        .onChange(of: model.loginModel?.errorMessage) { message in
            if let string = message, !string.isEmpty {
                errorMessage = string
            }
        }
        .onChange(of:  model.invoiceLoginModel.isLoggedIn) { loggedIn in
            if loggedIn, let info =  model.invoiceLoginModel.loginInfo {
                print("user is logged in \(info))")
                model.invoiceLoginModel.actionPublisher.send(["action": LoginViewModel.Action.save.rawValue])
            }
        }
        .onChange(of:  model.invoiceLoginModel.isValid) { isValid in
            if model.isWaiting {
                canLogin = false
            } else {
                canLogin = isValid
            }
        }
        .onChange(of:  model.invoiceLoginModel.isSaved) { isSaved in
            if isSaved {
                print("invoiceLoginModel saved.")
                presentationMode.wrappedValue.dismiss()
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
                        Text(loginModel.username)
                    }
                },
                header: {
                    Text(LoginStrings.username.localizedString(domain))
                })
            .textCase(nil)
        }
        .onChange(of: loginModel.isLoggedIn) { loggedIn in
            if !loggedIn {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(action: {
                    loginModel.actionPublisher.send(["action": LoginViewModel.Action.remove.rawValue])
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

public struct InvoiceView: View {
    @ObservedObject var loginProcessor: InvoiceLoginProcessor
    @StateObject private var loginModel: InvoiceLoginModel

    @State private var showDetail = false
    
    init(model: InvoiceLoginProcessor) {
        self.loginProcessor = model
        self._loginModel = StateObject(wrappedValue: model.invoiceLoginModel)

    }
    @ViewBuilder
    var content: some View {
        if loginModel.paymentUsername != nil {
            InvoiceDetailView(model: loginModel)
        } else {
            InvoiceLoginView(model: self.loginProcessor)
        }
    }

    public var body: some View {
        content
            .onAppear {
                if loginModel.paymentUsername != nil {
                    showDetail = true
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title"))
    }
}
