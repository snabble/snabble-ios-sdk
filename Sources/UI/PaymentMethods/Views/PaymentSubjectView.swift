//
//  PaymentSubjectView.swift
//  
//
//  Created by Uwe Tilemann on 30.06.23.
//

import Foundation
import SwiftUI

public struct PaymentSubjectView: View {
    @ObservedObject var viewModel: PaymentSubjectViewModel
    @State private var subject: String = ""
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer(minLength: 50)
                    Text(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.AlertDialog.message"))
                        .multilineTextAlignment(.center)
                        .font(.headline)
                    
                    Spacer(minLength: 50)
                }
                
                TextField(Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.AlertDialog.hint"), text: $subject)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.default)
                    .labelsHidden()
                
                Spacer()
                
                Button( action: {
                    viewModel.add()
                }) {
                    Text(keyed: "Snabble.Payment.ExternalBilling.AlertDialog.add")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .opacity(!viewModel.isValid ? 0.5 : 1.0)
                .disabled(!viewModel.isValid)
                .buttonStyle(AccentButtonStyle())
                
                Button( action: {
                    viewModel.skip()
                }) {
                    Text(keyed: "Snabble.Payment.ExternalBilling.AlertDialog.skip")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            
            Button(action: {
                viewModel.cancel()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding([.top, .trailing], 20)
            }
        }
        .onChange(of: subject) { newSubject in
            viewModel.subject = newSubject
        }
        .background(Color.systemBackground)
        .frame(minHeight: 250)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
