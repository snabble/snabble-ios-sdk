//
//  UIView+RestrictDynamicTypeSize.swift
//  Snabble
//
//  Created by Anastasia Mishur on 26.05.22.
//

import UIKit

extension UIView {
    @available(iOS 15, *)
    func restrictDynamicTypeSize(from min: UIContentSizeCategory?, to max: UIContentSizeCategory?) {
        self.minimumContentSizeCategory = min
        self.maximumContentSizeCategory = max
    }
}
