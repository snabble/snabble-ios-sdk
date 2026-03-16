//
//  PaymentEditView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

// MARK: - Payment Method Edit View

public struct PaymentEditView: View {

    private let payment: Payment
    private let manager: PaymentMethodListManager
    private weak var analyticsDelegate: AnalyticsDelegate?
    private let onDelete: (Payment) -> Void

    @State private var showDeleteAlert = false

    public init(payment: Payment, manager: PaymentMethodListManager, analyticsDelegate: AnalyticsDelegate? = nil, onDelete: @escaping ((Payment) -> Void)) {
        self.payment = payment
        self.manager = manager
        self.analyticsDelegate = analyticsDelegate
        self.onDelete = onDelete
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
                    onDelete(payment)
                }
            }
    }

    private func handleDelete() {
        guard let detail = payment.detail else { return }
        
        PaymentMethodDetails.remove(detail)
        analyticsDelegate?.track(.paymentMethodDeleted(detail.displayName))
    }
}
