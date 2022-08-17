//
//  CouponViewModel.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit

class CouponViewModel {
    let coupon: Coupon

    var title: String { coupon.name }
    var subtitle: String? { coupon.description }
    var text: String? { coupon.promotionDescription }
    var disclaimer: String? { coupon.disclaimer }

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

    func loadImage(completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let imageUrl = coupon.imageURL else {
            completion(nil)
            return nil
        }

        let session = URLSession.shared
        let task = session.dataTask(with: imageUrl) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    return completion(nil)
                }

                let image = UIImage(data: data)
                completion(image)
            }
        }
        task.resume()
        return task
    }
}
