//
//  DynamicFont.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

// TODO: Need refactoring before creating public interface

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
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }

    func useDynamicFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
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

// TODO: Move to another file
extension UIView {
    func restrictDynamicTypeSize(from min: UIContentSizeCategory?, to max: UIContentSizeCategory?) {
        self.minimumContentSizeCategory = min
        self.maximumContentSizeCategory = max
    }
}
