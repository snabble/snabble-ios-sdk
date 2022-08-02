//
//  UIStackView+Remove.swift
//  Snabble
//
//  Created by Anastasia Mishur on 26.07.22.
//

import Foundation
import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { [self] view in
            removeArrangedSubview(view)
            NSLayoutConstraint.deactivate(view.constraints)
            view.removeFromSuperview()
        }
    }
}
