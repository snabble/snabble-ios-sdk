//
//  CouponManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import Combine

public protocol CouponManagerDelegate: AnyObject {
    func couponManager(_ couponManager: CouponManager, didActivateCoupon coupon: Coupon)
    func couponManager(_ couponManager: CouponManager, didDeactivateCoupon coupon: Coupon)
}

public final class CouponManager {
    public static let shared = CouponManager()

    public weak var delegate: CouponManagerDelegate?

    public private(set) lazy var shoppingCartManager: ShoppingCartManager = .shared

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shoppingCartUpdated(_:)),
            name: .snabbleCartUpdated,
            object: nil
        )
    }

    public func all(for projectId: Identifier<Project>?) -> [Coupon]? {
        Snabble.shared.metadata.projects.first(where: { $0.id == projectId })?.digitalCoupons
            .filter { $0.type != .unknown }
            .filter { $0.imageURL != nil }
    }

    public func activated(for projectId: Identifier<Project>?) -> [Coupon]? {
        all(for: projectId)?
            .filter { $0.isActivated }
    }

    @objc
    private func shoppingCartUpdated(_ notification: Notification) {
        let shoppingCart = shoppingCartManager.shoppingCart
        let projectId = shoppingCart?.projectId
        let shoppingCartCoupons = shoppingCart?.coupons
            .map {
                $0.coupon
            }
        all(for: projectId)?
            .filter {
                !(shoppingCartCoupons?.contains($0) ?? true)
            }
            .forEach {
                switchCoupon($0, to: .deactivate)
            }
    }

    public func reset(for projects: [Project]) {
        projects
            .compactMap { all(for: $0.id) }
            .joined()
            .forEach { deactivate(coupon: $0) }
    }
}

extension CouponManager {
    public func deactivate(coupon: Coupon) {
        switchCoupon(coupon, to: .deactivate)
        if let shoppingCart = shoppingCartManager.shoppingCart, coupon.projectID == shoppingCart.projectId {
            shoppingCart.removeCoupon(coupon)
        }
        delegate?.couponManager(self, didDeactivateCoupon: coupon)
    }

    public func activate(coupon: Coupon) {
        switchCoupon(coupon, to: .activate)
        if let shoppingCart = shoppingCartManager.shoppingCart, coupon.projectID == shoppingCart.projectId {
            shoppingCart.addCoupon(coupon)
        }
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
