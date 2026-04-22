//
//  CouponViewModel.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import SnabbleCore
import Combine
import SwiftUI
import SnabbleAssetProviding

@MainActor
public protocol CouponViewModelDelegate: AnyObject {
    func couponViewModel(_ couponViewModel: CouponViewModel, shouldActivateCoupon coupon: Coupon) -> Bool
}

@Observable
@MainActor
public class CouponViewModel {
    public let coupon: Coupon

    public var title: String { coupon.name }
    public var subtitle: String? { coupon.description }
    public var text: String? { coupon.promotionDescription }
    public var disclaimer: String? { coupon.disclaimer }

    public var image: UIImage?

    public weak var delegate: CouponViewModelDelegate?
    private weak var imageTask: URLSessionDataTask?

    public var code: String? { coupon.code }

    public init(coupon: Coupon) {
        self.coupon = coupon
    }

    public var isActivated: Bool {
        coupon.isActivated
    }

    public var validUntil: String {
        guard coupon.isValid else {
            return Asset.localizedString(forKey: "Snabble.Coupon.expired")
        }

        guard let validUntil = coupon.validUntil else {
            return Asset.localizedString(forKey: "Snabble.Coupon.validIndefinitely")
        }

        let now = Date()
        guard now < validUntil else {
            return Asset.localizedString(forKey: "Snabble.Coupon.expired")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.locale = Locale.current

        let dateString = formatter.string(from: validUntil)
        return Asset.localizedString(forKey: "Snabble.Coupons.expiresAtDate", arguments: dateString)
    }

    public var isNew: Bool {
        guard let validFrom = coupon.validFrom else {
            return false
        }

        let now = Date()
        let diff = Calendar.current.dateComponents([.hour], from: validFrom, to: now)
        return abs(diff.hour!) <= 72
    }

    @discardableResult
    public func loadImage(completion: (@Sendable (UIImage?) -> Void)? = nil) -> URLSessionDataTask? {
        guard let imageUrl = coupon.imageURL else {
            completion?(nil)
            return nil
        }
        imageTask?.cancel()
        imageTask = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, _ in
            Task { @MainActor in
                guard let data = data else {
                    return completion?(nil) ?? ()
                }

                let image = UIImage(data: data)
                self?.image = image

                completion?(image)
            }
        }
        imageTask?.resume()
        return imageTask
    }
}

extension CouponViewModel {
    public var buttonTitle: String {
        Asset.localizedString(forKey: coupon.isActivated ? "Snabble.Coupon.deactivate" : "Snabble.Coupon.activate")
    }

    @objc
    public func activateCoupon() {
        if delegate?.couponViewModel(self, shouldActivateCoupon: coupon) ?? true {
            Snabble.shared.couponManager.activate(coupon: coupon)
        }
    }

    @objc
    public func deactivateCoupon() {
        Snabble.shared.couponManager.deactivate(coupon: coupon)
    }

    @objc
    public func toggleActivation() {
        if coupon.isActivated {
            deactivateCoupon()
        } else {
            activateCoupon()
        }
    }
}
