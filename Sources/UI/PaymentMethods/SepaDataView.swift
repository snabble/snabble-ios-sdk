//
//  SepaDataView.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import SwiftUI
import Combine
import SnabbleCore

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

private struct Country: Equatable, Comparable {
    static func < (lhs: Country, rhs: Country) -> Bool {
        lhs.name < rhs.name
    }

    let id: String
    var name: String
}

private func getLocales() -> [Country] {
    if #available(iOS 16, *) {
        let locales = Locale.Region.isoRegions
            .filter { $0.isISORegion && $0.subRegions.isEmpty }
            .compactMap { Country(id: $0.identifier, name: Locale.current.localizedString(forRegionCode: $0.identifier) ?? $0.identifier)}
            .sorted()
        return locales
    } else {
        let locales = Locale.isoRegionCodes
            .compactMap { Country(id: $0, name: Locale.current.localizedString(forRegionCode: $0) ?? $0)}
            .sorted()
        return locales
    }
}

public struct CountryPicker: View {
    @Binding var selectedCountry: String
    
    public var body: some View {
        Picker(SepaStrings.countryCode.localizedString, selection: $selectedCountry) {
            ForEach(getLocales(), id: \.id) { country in
                Text(country.name)
                    .tag(country.id)
            }
        }
    }
}

extension String {
    var flag: String? {
        let base: UInt32 = 127397
        var result = ""
        for char in self.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + char.value) {
                result.unicodeScalars.append(flagScalar)
            }
        }
        return result.isEmpty ? nil : String(result)
    }
}

public struct IbanCountryPicker: View {
    var model: SepaDataModel
    @Binding var selectedCountry: String
    
    public var body: some View {
        if model.countries.count == 1, let country = model.countries.first {
            if let flag = country.flag {
                Text(flag + " " + country)
                    .foregroundColor(.systemGray)
            } else {
                Text(country)
                    .foregroundColor(.systemGray)
            }
        } else {
            Picker("", selection: $selectedCountry) {
                ForEach(model.countries, id: \.self) { country in
                    Text(country)
                        .tag(country)
                }
            }
            .frame(width: 64)
        }
    }
}

public struct SepaDataEditorView: View {
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
            Text(keyed: "Snabble.save")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
        .disabled(!self.model.isValid)
        .opacity(!self.model.isValid ? 0.5 : 1.0)
    }

    @ViewBuilder
    var ibanCountryView: some View {
        IbanCountryPicker(model: model, selectedCountry: $localCountryCode)
            .foregroundColor(Color.accent())
    }
    
    @ViewBuilder
    var ibanNumberView: some View {
        TextField(SepaStrings.iban.localizedString, value: $model.ibanNumber, formatter: model.formatter)
            .keyboardType(.numberPad)
    }
    
    @ViewBuilder
    var editor: some View {
        Form {
            Section(
                content: {
                    TextField(SepaStrings.lastname.localizedString, text: $model.lastname)
                    HStack {
                        ibanCountryView
                        ibanNumberView
                    }
                    .onChange(of: localCountryCode) { newCountry in
                        localCountryCode = newCountry
                        self.model.ibanCountry = localCountryCode
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
                    Text(keyed: "Snabble.Payment.SEPA.hint")
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                })
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.SEPA.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: action) { _ in
            if self.model.isValid {
                hideKeyboard()
                self.save()
            }
        }
    }
    
    public var body: some View {
        editor
    }
    func save() {
        Task {
            do {
                try await self.model.save()
            } catch {
                DispatchQueue.main.async {
                    let alert = AlertView(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.encryptionError"))
                    
                    alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default))
                    alert.show()
                }
            }
        }
    }

}

public struct SepaDataDisplayView: View {
    @ObservedObject var model: SepaDataModel
    @State private var showingAlert = false
    
    public init(model: SepaDataModel) {
        self.model = model
    }
    
    @ViewBuilder
    var displayData: some View {
        Form {
            Section(
                content: {
                    VStack(alignment: .leading) {
                        HStack {
                            if let imageName = model.imageName, let uiImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) {
                                Image(uiImage: uiImage)
                            }
                            Text(model.iban)
                        }
                        HStack {
                            if let lastName = model.paymentDetailName {
                                Text(SepaStrings.payer.localizedString + ": " + lastName)
                            }
                            if let mandate = model.paymentDetailMandate {
                                Spacer()
                                Text(SepaStrings.mandate.localizedString + ": " + mandate)
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                    }
                }
            )
        }
        .navigationBarItems(trailing: Button(action: {
            showingAlert = true
        }) {
            Image(systemName: "trash")
        }
        )
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(Asset.localizedString(forKey: "Snabble.Payment.SEPA.title")),
                  message: Text(Asset.localizedString(forKey: "Snabble.Payment.Delete.message")),
                  dismissButton: .destructive(Text(Asset.localizedString(forKey: "Snabble.delete"))) {
                self.model.remove()
            })
        }

    }
    
    public var body: some View {
        displayData
    }
}

public struct SepaDataView: View {
    @ObservedObject var model: SepaDataModel
    
    public init(model: SepaDataModel) {
        self.model = model
    }
    
    public var body: some View {
        if model.isEditable {
            SepaDataEditorView(model: model)
        } else {
            SepaDataDisplayView(model: model)
        }
    }
}
