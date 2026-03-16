//
//  PaymentEditView.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

// MARK: - Payment Method Edit View

public struct PaymentEditView: View {
    @Environment(\.dismiss) private var dismiss

    private let payment: Payment
    private let manager: PaymentMethodListManager
    private weak var analyticsDelegate: AnalyticsDelegate?

    @State private var showDeleteAlert = false

    public init(payment: Payment, manager: PaymentMethodListManager, analyticsDelegate: AnalyticsDelegate? = nil) {
        self.payment = payment
        self.manager = manager
        self.analyticsDelegate = analyticsDelegate
    }

    public var body: some View {
        payment.editView(for: payment, manager: manager, analyticsDelegate: analyticsDelegate)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert(
                Asset.localizedString(forKey: "Snabble.Payment.Delete.message"),
                isPresented: $showDeleteAlert
            ) {
                Button(Asset.localizedString(forKey: "Snabble.no"), role: .cancel) { }
                Button(Asset.localizedString(forKey: "Snabble.yes"), role: .destructive) {
                    handleDelete()
                }
            }
    }

    private func handleDelete() {
        guard let detail = payment.detail else { return }

        PaymentMethodDetails.remove(detail)
        analyticsDelegate?.track(.paymentMethodDeleted(detail.displayName))
        dismiss()
    }
}
