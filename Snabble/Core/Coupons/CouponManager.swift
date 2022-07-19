//
//  CouponManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import Combine

final class CouponManager {
    static let shared = CouponManager()

    var projectId: Identifier<Project>? = nil {
        didSet {
            update()
        }
    }

    @Published private(set) var all: [Coupon] = [] {
        didSet {
            activated = all
                .filter { $0.projectID == projectId }
                .filter { $0.isActivated }
        }

    }
    @Published private(set) var activated: [Coupon] = []

    private init() {}

    private func update() {
        all = Snabble.shared.metadata.projects.first(where: { $0.id == projectId })?.digitalCoupons ?? []
    }

    func reset() {
        all.forEach { coupon in
            coupon.deactivate()
        }
    }
}

extension CouponManager {
    func deactivate(coupon: Coupon) {
        coupon.deactivate()
    }

    func activate(coupon: Coupon) {
        coupon.activate()
        
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

//
//private extension Defaults.Keys {
//    static let couponsActivated = Key<[String]>("couponsActivated", default: [])
//}
