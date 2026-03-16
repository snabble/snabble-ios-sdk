//
//  PaymentListEmptyView.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleAssetProviding

// MARK: - Payment Method List Empty View

public struct PaymentListEmptyView: View {
    public var body: some View {
        VStack(spacing: 20) {
            if let icon = Asset.image(named: "SnabbleSDK/payment/paymentCard") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(.secondary)
            }

            Text(Asset.localizedString(forKey: "Snabble.PaymentMethods.empty"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
