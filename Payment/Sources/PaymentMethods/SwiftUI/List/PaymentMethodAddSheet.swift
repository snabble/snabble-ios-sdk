//
//  PaymentMethodAddSheet.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding
import LocalAuthentication

// MARK: - Add Payment Sheet

public struct PaymentMethodAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    let projectId: Identifier<SnabbleCore.Project>
    weak var analyticsDelegate: AnalyticsDelegate?

    @State private var manager: PaymentMethodListManager
    @State private var showAuthAlert = false
    @State private var deniedMethod: RawPaymentMethod?

    let onAction: (RawPaymentMethod) -> Void

    public init(projectId: Identifier<SnabbleCore.Project>, analyticsDelegate: AnalyticsDelegate? = nil, onAction: @escaping (RawPaymentMethod) -> Void) {
        self.projectId = projectId
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager(projectId: projectId))
        self.onAction = onAction
    }

    private func handleMethodSelection(_ method: RawPaymentMethod) {
        // Check if adding is allowed (biometric/passcode requirement)
        if !method.isAddingAllowed {
            deniedMethod = method
            showAuthAlert = true
            return
        }

        // Notify parent and let it handle navigation
        onAction(method)
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(manager.availableMethods, id: \.rawValue) { method in
                    Button {
                        handleMethodSelection(method)
                    } label: {
                        HStack(spacing: 12) {
                            if let icon = method.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                            }

                            Text(method.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(
                Asset.localizedString(forKey: "Snabble.PaymentMethods.noDeviceCode"),
                isPresented: $showAuthAlert
            ) {
                Button(Asset.localizedString(forKey: "Snabble.ok"), role: .cancel) { }
            } message: {
                Text(authAlertMessage)
            }
        }
    }

    private var authAlertMessage: String {
        let mode = BiometricAuthentication.supportedBiometry
        return mode == .none ?
            Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.noBiometry")
            : Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.biometry")
    }
}
