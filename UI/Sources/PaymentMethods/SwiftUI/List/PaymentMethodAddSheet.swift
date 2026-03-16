//
//  PaymentMethodAddSheet.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

// MARK: - Add Payment Sheet

struct PaymentMethodAddSheet: View {
    let projectId: Identifier<SnabbleCore.Project>
    weak var analyticsDelegate: AnalyticsDelegate?

    @State private var manager: PaymentMethodListManager
    @Environment(\.dismiss) private var dismiss

    init(projectId: Identifier<SnabbleCore.Project>, analyticsDelegate: AnalyticsDelegate?) {
        self.projectId = projectId
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager(projectId: projectId))
    }

    var body: some View {
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
            .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.choose"))
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
        }
    }

    private func handleMethodSelection(_ method: RawPaymentMethod) {
        // For now, this is a placeholder.
        // In a full implementation, we would need to handle navigation to the appropriate
        // edit view controller or SwiftUI view based on the payment method type.
        // This is complex because each payment method has different requirements.
        dismiss()
    }
}
