//
//  Cardable.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.07.22.
//

import Foundation
import UIKit

protocol Cardable: UIView {
    func enableCardStyle()
}

extension Cardable {
    func enableCardStyle() {
        layer.cornerRadius = 12
        layer.shadowOffset = .init(width: 0, height: 6)
        layer.shadowRadius = 6

        if self.traitCollection.userInterfaceStyle == .dark {
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOpacity = 0.3
        } else {
            layer.shadowColor = UIColor.darkGray.cgColor
            layer.shadowOpacity = 0.15
        }

        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    }
}
