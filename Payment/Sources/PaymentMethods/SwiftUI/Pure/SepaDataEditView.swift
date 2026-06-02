//
//  SepaDataEditView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
import SnabbleTheme

/// Pure SwiftUI view for editing SEPA payment data
/// Replaces SepaDataEditViewController for SwiftUI-native flows
public struct SepaDataEditView: View {
    @Bindable var model: SepaDataModel
    @Environment(\.dismiss) private var dismiss

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    public init(model: SepaDataModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            if model.isEditable {
                editorSection
                saveSection
            } else {
                displaySection
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Payment.SEPA.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !model.isEditable {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        handleRemove()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .disabled(isSaving)
    }

    // MARK: - Editor Section

    @ViewBuilder
    private var editorSection: some View {
        Section {
            TextField(SepaStrings.lastname.localizedString, text: $model.lastname)

            HStack {
                IbanCountryPicker(model: model)
                    .fixedSize()

                UIKitTextField(
                    SepaStrings.iban.localizedString,
                    text: $model.ibanNumber,
                    formatter: model.formatter,
                    content: {
                        IBANHintView(model: model)
                    }
                )
            }

            if model.policy == .extended {
                TextField(SepaStrings.city.localizedString, text: $model.city)
                CountryPicker(selectedCountry: $model.ibanCountry)
            }
        } header: {
            Text(Asset.localizedString(forKey: "Snabble.SEPA.helper"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .textCase(.none)
    }

    @ViewBuilder
    private var saveSection: some View {
        Section {
            Button {
                handleSave()
            } label: {
                if isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Text(keyed: "Snabble.save")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(ProjectPrimaryButtonStyle())
            .disabled(!model.isValid || isSaving)
            .opacity(!model.isValid || isSaving ? 0.5 : 1.0)
        } footer: {
            if !model.errorMessage.isEmpty {
                IBANErrorView(model: model)
            } else {
                Text(keyed: "Snabble.Payment.SEPA.hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Display Section

    @ViewBuilder
    private var displaySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let imageName = model.imageName,
                       let uiImage = Asset.image(named: "SnabbleSDK/payment/" + imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    Text(model.iban)
                        .font(.body)
                }

                HStack {
                    if let lastName = model.paymentDetailName {
                        Text("\(SepaStrings.payer.localizedString): \(lastName)")
                    }

                    if let mandate = model.paymentDetailMandate {
                        Spacer()
                        Text("\(SepaStrings.mandate.localizedString): \(mandate)")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        guard model.isValid else { return }

        isSaving = true

        Task {
            do {
                try await model.save()
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = Asset.localizedString(forKey: "Snabble.SEPA.encryptionError")
                    showError = true
                }
            }
        }
    }

    private func handleRemove() {
        model.remove()
        dismiss()
    }
}

#Preview("Edit Mode") {
    NavigationStack {
        SepaDataEditView(
            model: SepaDataModel(
                iban: "",
                countryCode: "DE",
                projectId: Identifier<SnabbleCore.Project>(rawValue: "test")
            )
        )
    }
}

#Preview("Display Mode") {
    NavigationStack {
        SepaDataEditView(
            model: SepaDataModel(
                paymentDetail: nil,
                iban: "DE89370400440532013000",
                lastname: "Max Mustermann",
                city: "Berlin",
                countryCode: "DE",
                projectId: Identifier<SnabbleCore.Project>(rawValue: "test")
            )
        )
    }
}
