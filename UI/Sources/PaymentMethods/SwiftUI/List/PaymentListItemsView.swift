//
//  PaymentListItemsView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore

// MARK: - Payment Method List Items View

public struct PaymentListItemsView: View {
    private let manager: PaymentMethodListManager
    private weak var analyticsDelegate: AnalyticsDelegate?

    @State private var selectedPayment: Payment?

    public init(manager: PaymentMethodListManager, analyticsDelegate: AnalyticsDelegate? = nil) {
        self.manager = manager
        self.analyticsDelegate = analyticsDelegate
    }

    public var body: some View {
        List {
            ForEach(manager.paymentGroups) { group in
                Section {
                    ForEach(group.items) { payment in
                        PaymentMethodRow(payment: payment)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if canNavigateToEdit(payment) {
                                    selectedPayment = payment
                                } else {
                                    selectedPayment = nil
                                }
                            }
                            .navigationDestination(item: $selectedPayment) { payment in
                                PaymentEditView(payment: payment, manager: manager, analyticsDelegate: analyticsDelegate) { payment in
                                    delete(payment: payment)
                                    selectedPayment = nil
                                }
                            }
                    }
                    .onDelete { indexSet in
                        handleDelete(in: group, at: indexSet)
                    }
                }
            }
        }
    }

    private func canNavigateToEdit(_ payment: Payment) -> Bool {
        guard let detail = payment.detail else { return false }

        // All payment methods with details can be edited
        switch detail.methodData {
        case .sepa, .payoneSepa, .teleCashCreditCard, .giropayAuthorization,
             .payoneCreditCard, .datatransAlias, .datatransCardAlias, .invoiceByLogin:
            return true
        case .tegutEmployeeCard:
            return false // No edit view available
        }
    }

    private func delete(payment: Payment) {
        if let detail = payment.detail {
            manager.removePayment(detail)
            analyticsDelegate?.track(.paymentMethodDeleted(detail.displayName))
       }
   }
    private func handleDelete(in group: PaymentGroup, at indexSet: IndexSet) {
        for index in indexSet {
            guard index < group.items.count else { continue }
            let payment = group.items[index]

            delete(payment: payment)
        }
    }
}
