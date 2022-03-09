//
//  DynamicFont.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

extension UIFont {
    static func preferredFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: textStyle)
            .addingAttributes([
                .traits: [ UIFontDescriptor.TraitKey.weight: weight ]
            ])
        return UIFont(descriptor: descriptor, size: 0)
    }
}

extension UILabel {
    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }

    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}

extension UITextView {
    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }

    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}

extension UITextField {
    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }

    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}

extension UIButton {
    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle) {
        titleLabel?.useDynamicFont(forTextStyle: textStyle)
    }

    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) {
        titleLabel?.useDynamicFont(forTextStyle: textStyle, weight: weight)
    }
}
