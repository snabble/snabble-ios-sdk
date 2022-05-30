//
//  UIView+RestrictDynamicTypeSize.swift
//  Snabble
//
//  Created by Anastasia Mishur on 26.05.22.
//

import UIKit

extension UIView {
    func restrictDynamicTypeSize(from min: UIContentSizeCategory?, to max: UIContentSizeCategory?) {
        if #available(iOS 15, *) {
            self.minimumContentSizeCategory = min
            self.maximumContentSizeCategory = max
        }
    }
}
