//
//  CouponManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import Combine

public protocol CouponManagerDelegate: AnyObject {
    func couponManager(_ couponManager: CouponManager, didChangeProjectId projectId: Identifier<Project>?)
    func couponManager(_ couponManager: CouponManager, didActivateCoupon coupon: Coupon)
    func couponManager(_ couponManager: CouponManager, didDeactivateCoupon coupon: Coupon)
}

public final class CouponManager {
    public static let shared = CouponManager()

    public weak var delegate: CouponManagerDelegate?

    public var projectId: Identifier<Project>? = nil {
        didSet {
            delegate?.couponManager(self, didChangeProjectId: projectId)
        }
    }

    public var all: [Coupon] {
        Snabble.shared.metadata.projects.first(where: { $0.id == projectId })?.digitalCoupons ?? []

    }

    public var activated: [Coupon] {
        all
            .filter { $0.projectID == projectId }
            .filter { $0.isActivated }
    }

    private init() {}

    public func all(for projectId: Identifier<Project>?) -> [Coupon]? {
        Snabble.shared.metadata.projects.first(where: { $0.id == projectId })?.digitalCoupons
    }

    public func reset() {
        all.forEach { coupon in
            switchCoupon(coupon, to: .deactivate)
        }
    }
}

extension CouponManager {
    public func deactivate(coupon: Coupon) {
        switchCoupon(coupon, to: .deactivate)
        delegate?.couponManager(self, didDeactivateCoupon: coupon)
    }

    public func activate(coupon: Coupon) {
        switchCoupon(coupon, to: .activate)
        delegate?.couponManager(self, didActivateCoupon: coupon)
    }

    private enum State {
        case activate
        case deactivate
    }

    private func switchCoupon(_ coupon: Coupon, to state: State) {
        let couponIds = UserDefaults.standard.stringArray(forKey: coupon.stateKey) ?? []
        var idSet = couponIds.reduce(into: Set<String>()) { partialResult, object in
            partialResult.insert(object)
        }

        switch state {
        case .activate:
            idSet.insert(coupon.id)
        case .deactivate:
            idSet.remove(coupon.id)
        }

        UserDefaults.standard.set(Array(idSet), forKey: coupon.stateKey)
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
