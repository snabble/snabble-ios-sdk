//
//  InvoiceLoginView.swift
//  
//
//  Created by Uwe Tilemann on 02.06.23.
//

import Foundation
import SwiftUI
import UIKit

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

extension InvoiceLoginModel {
    public var image: SwiftUI.Image? {
        guard let imageName = imageName, let uiImage: UIImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) else {
            return nil
        }
        return Image(uiImage: uiImage)
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
    @ObservedObject var model: InvoiceLoginProcessor
    @State private var showDetail = false
    
    @ViewBuilder
    var content: some View {
        if showDetail {
            InvoiceDetailView(model: model)
        } else {
            InvoiceLoginView(model: model)
        }
    }

    public var body: some View {
        content
            .onChange(of: model.invoiceLoginModel.isLoggedIn) { loggedIn in
                showDetail = loggedIn
            }
            .onAppear {
                if model.invoiceLoginModel.paymentUsername != nil {
                    showDetail = true
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title"))
    }
}
