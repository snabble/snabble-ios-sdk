//
//  Payment+EditView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore

// MARK: - Payment Edit View Extension

extension Payment {
    @MainActor
    @ViewBuilder
    public func editView(for payment: Payment, manager: PaymentMethodListManager, analyticsDelegate: AnalyticsDelegate? = nil) -> some View {
        if let detail = payment.detail {
            switch detail.methodData {
            case .payoneSepa:
                PayoneSepaEditView(detail: detail, projectId: manager.projectId)
            case .sepa:
                SepaEditView(detail: detail, analyticsDelegate: analyticsDelegate)
            case .teleCashCreditCard:
                TeleCashCreditCardEditView(detail: detail, analyticsDelegate: analyticsDelegate)
            case .giropayAuthorization:
                GiropayEditView(detail: detail, projectId: manager.projectId, analyticsDelegate: analyticsDelegate)
            case .payoneCreditCard:
                PayoneCreditCardEditView(detail: detail)
            case .invoiceByLogin:
                InvoiceLoginEditView(detail: detail, projectId: manager.projectId)
            case .datatransAlias, .datatransCardAlias:
                DatatransEditView(detail: detail, analyticsDelegate: analyticsDelegate)
            }
        } else {
            PaymentEditUnavailableView(message: "No detail available")
        }
    }
}
