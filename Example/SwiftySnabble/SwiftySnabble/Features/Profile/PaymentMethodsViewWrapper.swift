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

    var body: some View {
        Group {
            if let projectId = project?.id {
                PaymentMethodListView(projectId: projectId, analyticsDelegate: nil)
            } else {
                SnabbleEmptyView(
                    title: "Payments.emptyMessage".localized,
                    image: Image("CardPayment"),
                    imageWidth: 200
                )
            }
        }
    }
}

