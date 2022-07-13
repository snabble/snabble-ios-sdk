//
//  CouponManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation

final class CouponManager {
    static let shared = CouponManager()

    private(set) var all: [Coupon] = [] {
        didSet {
            activated = Set(all.filter { UserDefaults.standard.couponsActivated.contains($0.id) })
        }

    }
    @Published private(set) var activated: Set<Coupon> = [] {
        didSet {
            UserDefaults.standard.couponsActivated = activated.map { $0.id }
        }

    }

    private init() {

    }

    
}
//    static let shared = CouponManager()
//    @Published private(set) var coupons: [Coupon] = [] {
//        didSet {
//            activatedCoupons = Set(coupons.filter { Defaults[.couponsActivated].contains($0.id) })
//        }
//    }
//    @Published private(set) var activatedCoupons: Set<Coupon> = [] {
//        didSet {
//            Defaults[.couponsActivated] = activatedCoupons.map { $0.id }
//        }
//    }
//
//    private init() {
//        loadCoupons()
//
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(shoppingCartUpdated(_:)),
//            name: .snabbleCartUpdated,
//            object: nil
//        )
//    }
//
//    func reload() {
//        loadCoupons()
//    }
//

//
//    @objc
//    private func shoppingCartUpdated(_ notification: Notification) {
//        let shoppingCartCoupons = ShoppingCartManager.shared.cart?.coupons
//            .map {
//                $0.coupon
//            }
//        activatedCoupons = Set(shoppingCartCoupons ?? [])
//    }
//
//    func reset() {
//        activatedCoupons = []
//    }
//}
//
//extension CouponManager {
//    func deactivate(coupon: Coupon) {
//        activatedCoupons.remove(coupon)
//    }
//
//    func activate(coupon: Coupon) {
//        activatedCoupons.insert(coupon)
//    }
//}
//
//private extension Defaults.Keys {
//    static let couponsActivated = Key<[String]>("couponsActivated", default: [])
//}
