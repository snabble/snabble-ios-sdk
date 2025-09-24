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
import Observation
import SnabbleAssetProviding

protocol CouponViewModelDelegate: AnyObject {
    func couponViewModel(_ couponViewModel: CouponViewModel, shouldActivateCoupon coupon: Coupon) -> Bool
}

@Observable
public class CouponViewModel {
    let coupon: Coupon

    var title: String { coupon.name }
    var subtitle: String? { coupon.description }
    var text: String? { coupon.promotionDescription }
    var disclaimer: String? { coupon.disclaimer }
    
    var image: UIImage?

    weak var delegate: CouponViewModelDelegate?
    private weak var imageTask: URLSessionDataTask?

    var code: String? { coupon.code }

    init(coupon: Coupon) {
        self.coupon = coupon
    }

    var isActivated: Bool {
        coupon.isActivated
    }

    var validUntil: String {
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

    var isNew: Bool {
        guard let validFrom = coupon.validFrom else {
            return false
        }

        let now = Date()
        let diff = Calendar.current.dateComponents([.hour], from: validFrom, to: now)
        return abs(diff.hour!) <= 72
    }

    @discardableResult
    func loadImage(completion: ((UIImage?) -> Void)? = nil) -> URLSessionDataTask? {
        guard let imageUrl = coupon.imageURL else {
            completion?(nil)
            return nil
        }
        imageTask?.cancel()
        imageTask = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, _ in
            DispatchQueue.main.async {
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
    var buttonTitle: String {
        Asset.localizedString(forKey: coupon.isActivated ? "Snabble.Coupon.deactivate" : "Snabble.Coupon.activate")
    }

    @objc
    func activateCoupon() {
        if delegate?.couponViewModel(self, shouldActivateCoupon: coupon) ?? true {
            Snabble.shared.couponManager.activate(coupon: coupon)
        }
    }

    @objc
    func deactivateCoupon() {
        Snabble.shared.couponManager.deactivate(coupon: coupon)
    }

    @objc
    func toggleActivation() {
        if coupon.isActivated {
            deactivateCoupon()
        } else {
            activateCoupon()
        }
        // @Observable automatically handles change notifications
    }
}
