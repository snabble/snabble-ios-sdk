//
//  RawPaymentMethod+AddView.swift
//
//
//  Created by Uwe Tilemann on 16.03.26.
//

import SwiftUI
import LocalAuthentication

import SnabbleCore
import SnabbleComponents

// MARK: - Add View Extension

extension RawPaymentMethod {
    @MainActor
    @ViewBuilder
    public func addView(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate?) -> some View {
        switch self {
        case .deDirectDebit:
            sepaAddView(projectId: projectId, analyticsDelegate: analyticsDelegate)
        case .giropayOneKlick:
            GiropayAddView(projectId: projectId, analyticsDelegate: analyticsDelegate)
        case .creditCardMastercard, .creditCardVisa, .creditCardAmericanExpress:
            creditCardAddView(projectId: projectId, analyticsDelegate: analyticsDelegate)
        case .externalBilling:
            externalBillingAddView(projectId: projectId, analyticsDelegate: analyticsDelegate)
        case .twint, .postFinanceCard:
            datatransAddView(projectId: projectId, analyticsDelegate: analyticsDelegate)
        case .qrCodePOS, .qrCodeOffline, .customerCardPOS, .gatekeeperTerminal, .applePay:
            PaymentEditUnavailableView(message: "No add view available for this payment method")
        }
    }

    @MainActor
    @ViewBuilder
    private func sepaAddView(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate?) -> some View {
        if let projectId = projectId,
           let project = Snabble.shared.project(for: projectId),
           let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self }) {

            if descriptor.acceptedOriginTypes?.contains(.payoneSepaData) == true {
                PayoneSepaAddView(projectId: projectId)
            } else {
                SepaAddView(analyticsDelegate: analyticsDelegate)
            }
        } else {
            PaymentEditUnavailableView(message: "Project configuration not found")
        }
    }

    @MainActor
    @ViewBuilder
    private func creditCardAddView(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate?) -> some View {
        if let projectId = projectId,
           let project = Snabble.shared.project(for: projectId),
           let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self }),
           let brand = CreditCardBrand.forMethod(self) {

            if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
                TeleCashCreditCardAddView(brand: brand, projectId: projectId)
            } else if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
                PayoneCreditCardAddView(brand: brand, projectId: projectId)
            } else if descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true {
                DatatransAddView(method: self, projectId: projectId, analyticsDelegate: analyticsDelegate)
            } else {
                PaymentEditUnavailableView(message: "Credit card configuration not supported")
            }
        } else {
            PaymentEditUnavailableView(message: "Project configuration not found")
        }
    }

    @MainActor
    @ViewBuilder
    private func externalBillingAddView(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate?) -> some View {
        if let projectId = projectId,
           let project = Snabble.shared.project(for: projectId),
           let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self }),
           descriptor.acceptedOriginTypes?.contains(.contactPersonCredentials) == true {

            InvoiceLoginAddView(project: project)
        } else {
            PaymentEditUnavailableView(message: "Invoice login configuration not found")
        }
    }

    @MainActor
    @ViewBuilder
    private func datatransAddView(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate?) -> some View {
        if let projectId = projectId {
            DatatransAddView(method: self, projectId: projectId, analyticsDelegate: analyticsDelegate)
        } else {
            PaymentEditUnavailableView(message: "Project ID required")
        }
    }
}

// MARK: - Container Views for UIKit Add ViewControllers

struct GiropayAddView: View {
    let projectId: Identifier<SnabbleCore.Project>?
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        ContainerView(
            viewController: GiropayEditViewController(nil, for: projectId, with: analyticsDelegate)
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SepaAddView: View {
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        ContainerView(
            viewController: SepaEditViewController(nil, analyticsDelegate)
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PayoneSepaAddView: View {
    let projectId: Identifier<SnabbleCore.Project>

    var body: some View {
        ContainerView(
            viewController: SepaDataEditViewController(viewModel: SepaDataModel(projectId: projectId))
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TeleCashCreditCardAddView: View {
    let brand: CreditCardBrand
    let projectId: Identifier<SnabbleCore.Project>

    var body: some View {
        ContainerView(
            viewController: {
                let creditCardViewController = TeleCashCreditCardAddViewController(brand: brand, projectId: projectId)
                let viewController = UserPaymentViewController(
                    fields: TeleCashCreditCardAddViewController.defaultUserFields,
                    requiredFields: TeleCashCreditCardAddViewController.requiredUserFields
                )
                viewController.nextViewController = creditCardViewController
                return viewController
            }()
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PayoneCreditCardAddView: View {
    let brand: CreditCardBrand
    let projectId: Identifier<SnabbleCore.Project>

    var body: some View {
        ContainerView(
            viewController: PayoneCreditCardEditViewController(
                brand: brand,
                prefillData: Snabble.shared.userProvider?.getUser(),
                projectId
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InvoiceLoginAddView: View {
    let project: SnabbleCore.Project

    var body: some View {
        ContainerView(
            viewController: InvoiceViewController(
                viewModel: InvoiceLoginProcessor(invoiceLoginModel: InvoiceLoginModel(project: project))
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DatatransAddView: View {
    let method: RawPaymentMethod
    let projectId: Identifier<SnabbleCore.Project>?
    weak var analyticsDelegate: AnalyticsDelegate?

    var body: some View {
        if let projectId = projectId,
           let controller = Snabble.methodRegistry.createEntry(method: method, projectId, analyticsDelegate) {

            if let userValidation = controller as? UserInputConformance {
                ContainerView(
                    viewController: {
                        let viewController = UserPaymentViewController(
                            fields: type(of: userValidation).defaultUserFields,
                            requiredFields: type(of: userValidation).requiredUserFields
                        )
                        viewController.nextViewController = userValidation
                        return viewController
                    }()
                )
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContainerView(viewController: controller)
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            PaymentEditUnavailableView(message: "Datatrans configuration not available")
        }
    }
}
