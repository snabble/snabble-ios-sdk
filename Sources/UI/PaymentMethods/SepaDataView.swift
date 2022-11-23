//
//  SepaDataView.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import SwiftUI
import Combine
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

fileprivate struct Country {
    let id: String
    var name: String
}

fileprivate func getLocales() -> [Country] {
    if #available(iOS 16, *) {
        let locales = Locale.Region.isoRegions
            .filter { $0.isISORegion && $0.subRegions.isEmpty }
            .compactMap { Country(id: $0.identifier, name: Locale.current.localizedString(forRegionCode: $0.identifier) ?? $0.identifier)}
        return locales
    } else {
        let locales = Locale.isoRegionCodes
            .compactMap { Country(id: $0, name: Locale.current.localizedString(forRegionCode: $0) ?? $0)}
        return locales
    }
}

public struct CountryPicker: View {
    @Binding var selectedCountry: String
    
    public var body: some View {
        Picker(SepaStrings.countryCode.localizedString, selection: $selectedCountry) {
            ForEach(getLocales(), id: \.id) { country in
                Text(country.name).tag(country.id)
            }
        }
    }
}

public struct SepaDataView: View {
    @ObservedObject var model: SepaDataModel
    @State private var action = false
    @State private var localCountryCode = "DE"
    
    public init(model: SepaDataModel) {
        self.model = model
    }
    
    @ViewBuilder
    var button: some View {
        Button(action: {
            action.toggle()
        }) {
            Text(SepaStrings.save.localizedString)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
        .disabled(!self.model.isValid)
        .opacity(!self.model.isValid ? 0.5 : 1.0)
    }

    @ViewBuilder
    var ibanCountry: some View {
        TextField(localCountryCode, text: $model.ibanCountry)
            .frame(width: 40)
            .keyboardType(.asciiCapable)
    }
    
    @ViewBuilder
    var ibanNumber: some View {
        TextField(SepaStrings.iban.localizedString, text: $model.ibanNumber)
            .keyboardType(.numberPad)
    }
    
    @ViewBuilder
    var editor: some View {
        Form {
            Section(
                content: {
                    TextField(SepaStrings.lastname.localizedString, text: $model.lastname)
                    HStack {
                        ibanCountry
                        ibanNumber
                    }
                    if model.policy == .extended {
                        TextField(SepaStrings.city.localizedString, text: $model.city)
                        CountryPicker(selectedCountry: $model.countryCode)
                    }
                },
                footer: {
                    Text(model.hintMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                })
            Section(
                content: {
                    button
                },
                footer: {
                    if !model.errorMessage.isEmpty {
                        Text(model.errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                })
        }
        .onChange(of: action) { _ in
            if self.model.isValid {
                hideKeyboard()
                self.model.actionPublisher.send(["action": "save"])
            }
        }
        .onAppear {
            localCountryCode = Locale.current.countryCode
        }
    }
    
    @ViewBuilder
    var display: some View {
        Form {
            Section(
                content: {
                    HStack {
                        if let imageName = model.imageName, let uiImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) {
                            Image(uiImage: uiImage)
                        }
                        Text(model.iban)
                    }
                }
            )
        }
        .navigationBarItems(trailing: 
            Button(action: {
                self.model.actionPublisher.send(["action": "remove"])
            }) {
                Image(systemName: "trash")
            }
        )
    }
    
    public var body: some View {
        if model.isEditable {
            editor
        } else {
            display
        }
    }
}

