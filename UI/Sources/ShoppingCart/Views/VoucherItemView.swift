//
//  VoucherItemView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 10.12.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding

extension VoucherType {
    var name: String {
        switch self {
        case .depositReturn:
            return Asset.localizedString(forKey: "Snabble.ShoppingCart.DepositReturn.title")
        default:
            return ""
        }
    }
}

extension Voucher {
    var name: String {
        return type.name
    }
}

struct VoucherItemView: View {
    @EnvironmentObject var cartModel: ShoppingCartViewModel
    
    @ScaledMetric var imgSize: CGFloat = 22

    let voucher: Voucher
    let lineItems: [CheckoutInfo.LineItem]
    let onDelete: () -> Void
        
    init(voucher: Voucher, lineItems: [CheckoutInfo.LineItem], onDelete: @escaping () -> Void) {
        self.voucher = voucher
        self.lineItems = lineItems
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(voucher.name)
                    self.regularPriceString
                }
                Spacer()
                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.projectPrimary())
                        .frame(width: imgSize, height: imgSize)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding(.leading)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            if let total = cartModel.total, total < 0 {
                Text(keyed: "Snabble.ShoppingCart.DepositReturn.message")
                    .cartInfo()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.systemRed)
            }
        }
    }
    
    private var regularPrice: Int {
        lineItems.compactMap { $0.totalPrice }.reduce(0, +)
    }
    
    @ViewBuilder private var regularPriceString: some View {
        let price = regularPrice
        if price != 0 {
            Text(PriceFormatter(SnabbleCI.project).format(price))
                .bold()
        }
    }

}
