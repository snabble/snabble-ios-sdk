//
//  TeleCashCreditCardDisplayView.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

/// Pure SwiftUI view for displaying TeleCash credit card details
/// Replaces TeleCashCreditCardEditViewController for SwiftUI-native flows
public struct TeleCashCreditCardDisplayView: View {
    let detail: PaymentMethodDetail
    weak var analyticsDelegate: AnalyticsDelegate?


    private var brand: CreditCardBrand?
    private var cardNumber: String?
    private var expirationDate: String?

    public init(detail: PaymentMethodDetail, analyticsDelegate: AnalyticsDelegate? = nil) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate

        // Extract credit card data from detail
        if case .teleCashCreditCard(let data) = detail.methodData {
            self.brand = data.brand
            self.cardNumber = data.displayName
            self.expirationDate = data.expirationDate
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Explanation text
                Text(Asset.localizedString(forKey: "Snabble.CC.editingHint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                // Card number field
                VStack(alignment: .leading, spacing: 8) {
                    Text(Asset.localizedString(forKey: "Snabble.CC.cardNumber"))
                        .font(.body)

                    Text(cardNumber ?? "")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Expiration date field
                VStack(alignment: .leading, spacing: 8) {
                    Text(Asset.localizedString(forKey: "Snabble.CC.validUntil"))
                        .font(.body)

                    Text(expirationDate ?? "")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle(brand?.displayName ?? Asset.localizedString(forKey: "Snabble.Payment.creditCard"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            analyticsDelegate?.track(.viewPaymentMethodDetail)
        }
    }

}

//#Preview("Visa Card") {
//    NavigationStack {
//        // Create a mock detail for preview
//        let mockData = TeleCashCreditCardData(
//            brand: .visa,
//            displayName: "4242 4242 4242 4242",
//            expirationDate: "12/25"
//        )
//        let mockDetail = PaymentMethodDetail(
//            id: UUID(),
//            methodData: .teleCashCreditCard(mockData),
//            origin: .telecashCreditCard,
//            projectId: nil
//        )
//
//        TeleCashCreditCardDisplayView(
//            detail: mockDetail,
//            analyticsDelegate: nil
//        )
//    }
//}
//
//#Preview("Mastercard") {
//    NavigationStack {
//        let mockData = TeleCashCreditCardData(
//            brand: .mastercard,
//            displayName: "5555 5555 5555 4444",
//            expirationDate: "03/27"
//        )
//        let mockDetail = PaymentMethodDetail(
//            id: UUID(),
//            methodData: .teleCashCreditCard(mockData),
//            origin: .telecashCreditCard,
//            projectId: nil
//        )
//
//        TeleCashCreditCardDisplayView(
//            detail: mockDetail,
//            analyticsDelegate: nil
//        )
//    }
//}
