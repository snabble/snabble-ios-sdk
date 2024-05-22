//
//  CodeView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI

struct CodeView: View {
    @Binding var phoneNumber: String
    @State var otp: String = ""
    
    @Binding var showProgress: Bool
    @Binding var footerMessage: String
    
    var verifyCode: (_ code: String, _ phoneNumber: String) -> Void
    var rerequestCode: (_ phoneNumber: String) -> Void
    
    private var isEnabled: Bool {
        otp.count == 6
    }
    
    private enum Field: Hashable {
        case code
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 24) {
                Text("Please enter your code:")
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                TextField("Code", text: $otp)
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
                            verifyCode(otp, phoneNumber)
                        }
                    }
            }
            
            ProgressButtonView(
                title: "Continue",
                showProgress: $showProgress,
                action: {
                    verifyCode(otp, phoneNumber)
                })
            .buttonStyle(AccentButtonStyle(disabled: !isEnabled))
            .disabled(!isEnabled)
            
            LockedButtonView(
                title: "Request code again",
                action: {
                    rerequestCode(phoneNumber)
                })
            
            Text(footerMessage)
                .font(.footnote)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .onAppear {
            focusedField = .code
        }
        .navigationTitle("Code")
    }
}
