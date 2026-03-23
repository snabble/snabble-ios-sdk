//
//  CouponsView.swift
//  Snabble
//
//  Swift 6.2 Migration - SwiftUI replacement for CouponsViewController
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

public struct CouponsView: View {
    let coupons: [Coupon]
    let onCouponTap: (Coupon) -> Void
    
    public init(coupons: [Coupon], onCouponTap: @escaping (Coupon) -> Void) {
        self.coupons = coupons
        self.onCouponTap = onCouponTap
    }
    
    public var body: some View {
        Group {
            if coupons.isEmpty {
                Text(keyed: "Snabble.Coupons.none")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        ForEach(coupons, id: \.id) { coupon in
                            CouponCardView(coupon: coupon)
                                .frame(width: cardWidth(for: coupons.count))
                                .frame(height: 355)
                                .onTapGesture {
                                    onCouponTap(coupon)
                                }
                        }
                    }
                    .padding(.horizontal, 25)
                }
                .background(Color.clear)
            }
        }
    }
    
    private func cardWidth(for count: Int) -> CGFloat {
        // Match UIKit logic: single coupon uses full width minus padding
        count == 1 ? UIScreen.main.bounds.width - 50 : 265
    }
}
