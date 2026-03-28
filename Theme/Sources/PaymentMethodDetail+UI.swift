//
//  PaymentMethodDetail+UI.swift
//  Snabble
//
//  Created by Uwe Tilemann on 27.03.26.
//
import UIKit

import SnabbleCore
import SnabbleAssetProviding

extension PaymentMethodDetail {
    public var icon: UIImage? {
        return Asset.image(named: "SnabbleSDK/payment/" + self.imageName)
    }
}


