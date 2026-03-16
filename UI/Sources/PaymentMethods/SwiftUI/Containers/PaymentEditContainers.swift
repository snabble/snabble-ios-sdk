//
//  PaymentEditContainers.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleComponents

// MARK: - Payment Edit Container Views

/// Pure SwiftUI view for Payone SEPA
struct PayoneSepaEditView: View {
    let detail: PaymentMethodDetail
    let projectId: Identifier<SnabbleCore.Project>?

    var body: some View {
        SepaDataEditView(
            model: SepaDataModel(detail: detail, projectId: projectId)
        )
    }
}

/// Pure SwiftUI view for TeleCash credit card display
struct TeleCashCreditCardEditView: View {
    let detail: PaymentMethodDetail
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        TeleCashCreditCardDisplayView(
            detail: detail,
            analyticsDelegate: analyticsDelegate
        )
    }
}

/// Container for legacy SEPA edit view controller
struct SepaEditView: View {
    let detail: PaymentMethodDetail
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        ContainerView(
            viewController: SepaEditViewController(detail, analyticsDelegate)
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Container for Giropay edit view controller
struct GiropayEditView: View {
    let detail: PaymentMethodDetail
    let projectId: Identifier<SnabbleCore.Project>?
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        ContainerView(
            viewController: GiropayEditViewController(detail, for: projectId, with: analyticsDelegate)
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Container for Payone credit card edit view controller
struct PayoneCreditCardEditView: View {
    let detail: PaymentMethodDetail

    var body: some View {
        ContainerView(
            viewController: PayoneCreditCardEditViewController(detail, prefillData: Snabble.shared.userProvider?.getUser())
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Container for invoice login edit view controller
struct InvoiceLoginEditView: View {
    let detail: PaymentMethodDetail
    let projectId: Identifier<SnabbleCore.Project>?

    var body: some View {
        if let projectId,
           let project = Snabble.shared.project(for: projectId) {
            let model = InvoiceLoginProcessor(
                invoiceLoginModel: InvoiceLoginModel(paymentDetail: detail, project: project)
            )
            ContainerView(
                viewController: InvoiceViewController(viewModel: model)
            )
            .navigationBarTitleDisplayMode(.inline)
        } else {
            PaymentEditUnavailableView(message: "Project not available")
        }
    }
}

/// Container for Datatrans (Twint/PostFinance) edit view controller
struct DatatransEditView: View {
    let detail: PaymentMethodDetail
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        if let editVC = Snabble.methodRegistry.create(detail: detail, analyticsDelegate: analyticsDelegate) {
            ContainerView(viewController: editVC)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            PaymentEditUnavailableView(message: "Edit view not available")
        }
    }
}

/// Fallback view for payment methods without edit functionality
struct PaymentEditUnavailableView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
    }
}
