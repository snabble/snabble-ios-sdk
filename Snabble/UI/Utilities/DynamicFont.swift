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
