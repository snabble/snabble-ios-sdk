//
//  CouponsViewControllerSwiftUI.swift
//  Snabble
//
//  Swift 6.2 Migration - SwiftUI wrapper for CouponsViewController
//

import Foundation
import UIKit
import SwiftUI
import SnabbleCore

public final class CouponsViewControllerSwiftUI: UIHostingController<CouponsView> {
    public var onCouponSelected: ((Coupon) -> Void)?

    public var coupons: [Coupon] {
        didSet {
            rootView = CouponsView(coupons: coupons) { [weak self] coupon in
                self?.onCouponSelected?(coupon)
            }
        }
    }

    public init(coupons: [Coupon]) {
        self.coupons = coupons
        super.init(rootView: CouponsView(coupons: coupons, onCouponTap: { _ in }))

        // Update the rootView with the closure that captures self
        self.rootView = CouponsView(coupons: coupons) { [weak self] coupon in
            self?.onCouponSelected?(coupon)
        }

        view.backgroundColor = .clear
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
