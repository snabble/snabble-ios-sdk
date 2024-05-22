//
//  NumberView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-02-07.
//

import SwiftUI
import SnabblePhoneAuth

private struct LabelWithImageAccent: View {
    /// The title which will be passed to the title attribute of the Label View.
    let title: String
    /// The name of the image to pass into the Label View.
    let systemName: String
    
    var body: some View {
        Label(title: {
            Text(self.title)
        }, icon: {
            Image(systemName: systemName)
                .foregroundStyle(.blue)
        })
    }
}

struct NumberView: View {
    let countries: [Country] = Country.all
    
    @State var country: Country = Country.germany
    @State var number: String = ""
    
    @Binding var showProgress: Bool
    @Binding var footerMessage: String
    
    var callback: (_ phoneNumber: String) -> Void
    
    private enum Field: Hashable {
        case phoneNumber
    }
    
    @FocusState private var focusedField: Field?
    
    private var isEnabled: Bool {
        number.count > 3 && !showProgress
    }
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 16) {
                Text("Please enter your phone number:")
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .padding(.top, 8)
            .font(.callout)
            
            VStack(spacing: 16) {
                HStack {
                    CountryCallingCodeButtonView(countries: countries, selectedCountry: $country)
                        .padding(12)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    TextField("Phone number", text: $number)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phoneNumber)
                        .submitLabel(.continue)
                        .padding(12)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onSubmit {
                            submit()
                        }
                }
                .disabled(showProgress)
                .padding(.horizontal, 24)
                
                ProgressButtonView(
                    title: "Continue",
                    showProgress: $showProgress,
                    action: {
                        submit()
                })
                .buttonStyle(AccentButtonStyle(disabled: !isEnabled))
                .disabled(!isEnabled)
            }
            
            VStack(spacing: 12) {
                Text(footerMessage)
                    .foregroundColor(.red)
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .onAppear {
            focusedField = .phoneNumber
        }
        .navigationTitle("Sign in")
    }
    
    private func submit() {
        callback("+\(country.callingCode)\(number)")
    }
}
