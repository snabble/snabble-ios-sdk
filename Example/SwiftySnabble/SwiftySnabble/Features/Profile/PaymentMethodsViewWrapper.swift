//
//  PaymentMethodsViewWrapper.swift
//  SwiftySnabble
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//
import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI
import SnabbleComponents

extension String {
    /// Localize the String on the `main` Bundle and `nil` table.
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

struct PaymentMethodsViewWrapper: View {

    var project: SnabbleCore.Project?
    
    @State private var paymentVC: PaymentMethodListViewController?
    
    @ViewBuilder
    var content: some View {
        if let paymentVC, let project {
            ContainerView(viewController: paymentVC)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            paymentVC.addPaymentMethod(for: project.id, analyticsDelegate: nil)
                        }, label: {
                            Label("Add Payment", systemImage: "plus")
                        })
                    }
                }
        } else {
            SnabbleEmptyView(
                title: "Payments.emptyMessage".localized,
                image: Image("CardPayment"),
                imageWidth: 200)
        }
    }

    var body: some View {
        content
            .task {
                if paymentVC == nil, let projectId = project?.id {
                    paymentVC = PaymentMethodListViewController(for: projectId, nil)
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
    }
}

