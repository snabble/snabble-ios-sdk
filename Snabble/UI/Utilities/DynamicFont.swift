//
//  DynamicFont.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

// TODO: Need refactoring before creating public interface

// First we declare list of Styles as they are listed at Confluence, that are using in the SDK
// (maybe change it to a struct with variables, or implement as a protocol)
enum StyleKey: String {
        case largeTitle, title1, title2, title3
        case headline, subheadline, body
        case footnote, caption1, caption2
}

// Then linking our StyleKeys with system TextStyles, cause we are not using all system styles (for example '.callout')
extension UIFont.TextStyle {
    init (_ styleKey: StyleKey) {
        switch styleKey {
        case .largeTitle: self = .largeTitle
        case .title1: self = .title1
        case .title2: self = .title2
        case .title3: self = .title3
        case .headline: self = .headline
        case .subheadline: self = .subheadline
        case .body: self = .body
        case .footnote: self = .footnote
        case .caption1: self = .caption1
        case .caption2: self = .caption2
        }
    }
}

// Also weight could be linked with StyleKey, and this will allow to remove weight as a parameter for methods below https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
extension UIFont.Weight {
    init (_ styleKey: StyleKey) {
        switch styleKey {
        case .headline: self = .semibold
        default: self = .regular
        }
    }
}

extension UIFont {
    static func preferredFont(forTextStyle textStyle: StyleKey, weight: UIFont.Weight = .regular) -> UIFont {
        let style = UIFont.TextStyle(textStyle)
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: style)
            .addingAttributes([
                .traits: [ UIFontDescriptor.TraitKey.weight: weight ]
            ])
        return UIFont(descriptor: descriptor, size: 0)
    }
}

extension UILabel {
    func useDynamicFont(forTextStyle textStyle: StyleKey) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }

    func useDynamicFont(forTextStyle textStyle: StyleKey, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }
}

extension UITextView {
    func useDynamicFont(forTextStyle textStyle: StyleKey) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }

    func useDynamicFont(forTextStyle textStyle: StyleKey, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}

extension UITextField {
    func useDynamicFont(forTextStyle textStyle: StyleKey) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }

    func useDynamicFont(forTextStyle textStyle: StyleKey, weight: UIFont.Weight) {
        font = .preferredFont(forTextStyle: textStyle, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}

extension UIButton {
    func useDynamicFont(forTextStyle textStyle: StyleKey) {
        titleLabel?.useDynamicFont(forTextStyle: textStyle)
    }

    func useDynamicFont(forTextStyle textStyle: StyleKey, weight: UIFont.Weight = .regular) {
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
