//
//  PaymentMethodRow.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            if let icon = payment.detail?.icon ?? payment.method.icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            if let detail = payment.detail {
                Text(detail.displayName)
                    .font(.body)
            } else {
                Text(payment.method.displayName)
                    .font(.body)
            }

            Spacer()

            if payment.detail != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
