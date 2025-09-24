//
//  SepaDataView.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import SwiftUI
import Combine
import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents

#if canImport(UIKit)
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct UIKitLabel: UIViewRepresentable {
    fileprivate var configuration = { (_: UILabel) in }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        let label = UILabel()
        return label
    }

    func updateUIView(_ uiView: UILabel, context: UIViewRepresentableContext<Self>) {
        configuration(uiView)
    }
}

extension String {
    var countryFlagSymbol: String? {
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

private struct Country {
    let id: String
    var name: String
}

private func getLocales() -> [Country] {
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

struct IBANHintView: View {
    @State var model: SepaDataModel
    @State private var attributedString: NSAttributedString

    init(model: SepaDataModel) {
        self.model = model
        attributedString = model.attributedInputPlaceholderString
    }

    private var hintMessage: String {
        return model.hintMessage.isEmpty ? IBANFormatter.HintState.checksum.localizedString : model.hintMessage
    }

    private var topPadding: CGFloat {
        if #available(iOS 15.0, *) {
            return 0
        } else {
            return -10
        }
    }

    private var bottomPadding: CGFloat {
        if #available(iOS 15.0, *) {
            return 0
        } else {
            return 2
        }
    }

    @ViewBuilder
    var placeholder: some View {
        if #available(iOS 15.0, *) {
            Text(AttributedString(attributedString))
                .truncationMode(model.lineBreakMode == .byTruncatingHead ? .head : .tail)
                .padding(.top, 4)
        } else {
            GeometryReader { geom in
                UIKitLabel {
                    $0.attributedText = attributedString
                    $0.lineBreakMode = model.lineBreakMode
                    $0.numberOfLines = 1
                }
                .frame(maxWidth: geom.size.width)
            }
        }
    }
    
    @ViewBuilder
    var message: some View {
        if model.ibanNumber.count == model.formatter.placeholder.count {
            if model.ibanIsValid {
                Label(SepaStrings.validIBAN.localizedString, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label(SepaStrings.invalidIBAN.localizedString, systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        } else {
            Text(hintMessage)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            placeholder
            HStack {
                message
                    .font(.footnote)
                    .padding(.top, topPadding)
                    .padding(.bottom, bottomPadding)
                Spacer()
            }
            .frame(minWidth: 280)
       }
    }

    var body: some View {
        content
            .onChange(of: model.ibanNumber) {
                attributedString = model.attributedInputPlaceholderString
            }
    }
}

struct IBANErrorView: View {
    @State var model: SepaDataModel

    @ViewBuilder
    var content: some View {
        if !model.errorMessage.isEmpty {
            Label(model.errorMessage, systemImage: "xmark.circle.fill")
                .font(.footnote)
                .foregroundColor(.red)
        }
    }

    var body: some View {
        content
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

public struct IbanCountryPicker: View {
    @State var model: SepaDataModel

    public var body: some View {
        if model.countries.count == 1, let country = model.countries.first {
            Text(country)
                .foregroundColor(.systemGray)
        } else {
            Picker("", selection: $model.ibanCountry) {
                ForEach(model.countries, id: \.self) { country in
                    Text(country)
                        .tag(country)
                }
            }
        }
    }
}

public struct SepaDataEditorView: View {
    @State var model: SepaDataModel
    @State private var country: String

    public init(model: SepaDataModel) {
        self.model = model
        country = model.formatter.ibanDefinition.country
    }

    @ViewBuilder
    var button: some View {
        Button(action: {
            if self.model.isValid {
                hideKeyboard()
                self.model.actionPublisher.send(["action": "save"])
            }

        }) {
            Text(keyed: "Snabble.save")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ProjectPrimaryButtonStyle())
        .disabled(!self.model.isValid)
        .opacity(!self.model.isValid ? 0.5 : 1.0)
    }

    @ViewBuilder
    var ibanCountryView: some View {
        IbanCountryPicker(model: model)
            .foregroundColor(Color.projectPrimary())
    }

    @ViewBuilder
    var ibanNumberView: some View {
        UIKitTextField(SepaStrings.iban.localizedString, text: $model.ibanNumber, formatter: model.formatter, content: {
            IBANHintView(model: model)
        })
    }

    @ViewBuilder
    var extendedView: some View {
        if model.policy == .extended {
            TextField(SepaStrings.city.localizedString, text: $model.city)
            CountryPicker(selectedCountry: $model.ibanCountry)
        }
    }

    @ViewBuilder
    var footerView: some View {
        if !model.errorMessage.isEmpty {
            IBANErrorView(model: model)
        } else {
            Text(keyed: "Snabble.Payment.SEPA.hint")
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
        }
    }

    public var body: some View {
        Form {
            Section(
                content: {
                    TextField(SepaStrings.lastname.localizedString, text: $model.lastname)
                    HStack {
                        ibanCountryView.fixedSize()
                        ibanNumberView
                    }
                    extendedView
                },
                header: {
                    Text(keyed: "Snabble.SEPA.helper")
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            )
            .textCase(.none)
            Section(
                content: {
                    button
                },
                footer: {
                    footerView
                })
        }
    }
}

public struct SepaDataDisplayView: View {
    @State var model: SepaDataModel

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
                            if let imageName = model.imageName, let uiImage: UIImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) {
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
            askToRemove()
        }) {
            Image(systemName: "trash")
        }
        )
    }

    public var body: some View {
        displayData
    }

    private func askToRemove() {
        let alert = AlertView(title: Asset.localizedString(forKey: "Snabble.Payment.SEPA.title"), message: Asset.localizedString(forKey: "Snabble.Payment.Delete.message"))

        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.delete"), style: .destructive) { _ in
            self.model.actionPublisher.send(["action": "remove"])
            alert.dismiss(animated: false)
        })

        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
            alert.dismiss(animated: false)
        }))
    
        alert.show()
    }
}

public struct SepaDataView: View {
    @State var model: SepaDataModel

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
