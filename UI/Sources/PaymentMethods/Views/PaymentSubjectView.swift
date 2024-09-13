//
//  PaymentSubjectView.swift
//  
//
//  Created by Uwe Tilemann on 30.06.23.
//

import Foundation
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents

public struct PaymentSubjectView: View {
    @ObservedObject var viewModel: PaymentSubjectViewModel
    @State private var subject: String = ""
    
    private func subjectLimit() -> Int? {
        guard let projectId = Snabble.shared.checkInManager.shop?.projectId else {
            return nil
        }
        let customProperty = Snabble.shared.config.customProperties.first { customProperty, _ in
            switch customProperty {
            case .externalBillingSubjectLimit(let thisProjectId):
                if projectId.rawValue == thisProjectId {
                    return true
                }
            }
            return false
        }
        return customProperty?.value as? Int
    }
    
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
                    .limitInputLength(value: $subject, length: subjectLimit())
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
                .buttonStyle(ProjectPrimaryButtonStyle())
                
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
        .onChange(of: subject) { _, newSubject in
            viewModel.subject = newSubject
        }
        .background(Color.systemBackground)
        .frame(minHeight: 250)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
