//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 16.05.24.
//

import SwiftUI
import UIKit

extension SwiftUI.Font {
    public static func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> SwiftUI.Font? {
        return Asset.font(name, size: size, relativeTo: textStyle, domain: domain)
    }
    
    public static func buttonWeight(domain: Any? = Asset.domain) -> Font.Weight {
        return Asset.buttonFontWeight(domain: domain) ?? .bold
    }

    public static func buttonFont(domain: Any? = Asset.domain) -> Font {
        return Asset.buttonFont(domain: domain) ?? .body
    }
}

extension UIFont {
    public static func buttonWeight(domain: Any? = Asset.domain) -> UIFont.Weight {
        let weight = Asset.buttonFontWeight(domain: domain) ?? .bold

        switch weight {
        case .bold:
            return UIFont.Weight.bold
        default:
            return UIFont.Weight.regular
        }
    }
}
