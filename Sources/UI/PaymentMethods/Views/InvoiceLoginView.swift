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
    @Environment(\.presentationMode) var presentationMode

    let domain = "Snabble.Payment.ExternalBilling"
    
    public init(model: InvoiceLoginProcessor) {
        self.model = model
    }
    
    private var isDisabled: Bool {
        return !model.invoiceLoginModel.isValid || model.isWaiting
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
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private func login() {
        guard model.invoiceLoginModel.isValid else {
            return
        }
        hideKeyboard()
        model.invoiceLoginModel.actionPublisher.send(["action": LoginViewModel.Action.login.rawValue])
    }
    
    public var body: some View {
        Form {
            Section(
                content: {
                    TextField(LoginStrings.username.localizedString(domain), text: $model.invoiceLoginModel.username)
                        .keyboardType(.emailAddress)
                    SecureField(LoginStrings.password.localizedString(domain), text: $model.invoiceLoginModel.password) {
                        login()
                    }
                    .keyboardType(.default)
                },
                header: {
                    Text(LoginStrings.info.localizedString(domain))
                })
            .textCase(nil)
            Section(
                content: {
                    button
                },
                footer: {
                    if !model.invoiceLoginModel.errorMessage.isEmpty {
                        Text(model.invoiceLoginModel.errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                })
        }
        .onChange(of: model.invoiceLoginModel.isLoggedIn) { loggedIn in
            if loggedIn, let info = model.invoiceLoginModel.loginInfo {
                print("user is logged in \(info))")
                model.invoiceLoginModel.actionPublisher.send(["action": LoginViewModel.Action.save.rawValue])
            }
        }
        .onChange(of: model.invoiceLoginModel.isSaved) { isSaved in
            if isSaved {
                print("invoiceLoginModel saved.")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

public struct InvoiceDetailView: View {
    @ObservedObject var model: InvoiceLoginProcessor
    @Environment(\.presentationMode) var presentationMode
    let domain = "Snabble.Payment.ExternalBilling"
    
    public init(model: InvoiceLoginProcessor) {
        self.model = model
    }
        
    public var body: some View {
        Form {
            Section(
                content: {
                    HStack {
                        if let image = model.invoiceLoginModel.image {
                            image
                        }
                        Text(model.invoiceLoginModel.username)
                    }
                },
                header: {
                    Text(LoginStrings.username.localizedString(domain))
                })
            .textCase(nil)
        }
        .onChange(of: model.invoiceLoginModel.isLoggedIn) { loggedIn in
            if !loggedIn {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(action: {
                    model.invoiceLoginModel.actionPublisher.send(["action": LoginViewModel.Action.remove.rawValue])
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

public struct InvoiceView: View {
    @ObservedObject var loginProcessor: InvoiceLoginProcessor
    @ObservedObject var loginModel: InvoiceLoginModel

    @State private var showDetail = false
    
    init(model: InvoiceLoginProcessor) {
        self.loginProcessor = model
        self.loginModel = model.invoiceLoginModel
    }
    @ViewBuilder
    var content: some View {
        if showDetail {
            InvoiceDetailView(model: self.loginProcessor)
        } else {
            InvoiceLoginView(model: self.loginProcessor)
        }
    }

    public var body: some View {
        content
            .onChange(of: self.loginModel.isLoggedIn) { loggedIn in
                showDetail = loggedIn
            }
            .onChange(of: self.loginModel.isSaved) { saved in
                showDetail = saved
            }
            .onAppear {
                if self.loginModel.paymentUsername != nil {
                    showDetail = true
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title"))
    }
}
