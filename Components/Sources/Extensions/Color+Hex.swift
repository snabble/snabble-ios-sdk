//
//  Color+Hex.swift
//
//
//  Created by Andreas Osberghaus on 2024-09-09.
//

import SwiftUI

public extension Color {
    var hex: String {
        UIColor(self).hex
    }
    
    var hexWithAlpha: String {
        UIColor(self).hexWithAlpha
    }
    
    func hexDescription(_ includeAlpha: Bool = false) -> String {
        UIColor(self).hexDescription(includeAlpha)
    }
}

public extension Color {
    init(hex: String?) {
        self.init(UIColor(hex: hex))
    }
    
    init(hexLight: String?, hexDark: String?) {
        self.init(UIColor(hexLight: hexLight, hexDark: hexDark))
    }
}

public extension UIColor {
    convenience init(hex: String?) {
        let normalizedHexString: String = UIColor.normalize(hex)
        var c: UInt64 = 0
        Scanner(string: normalizedHexString).scanHexInt64(&c)
        self.init(
            red: UIColorMasks.redValue(c),
            green: UIColorMasks.greenValue(c),
            blue: UIColorMasks.blueValue(c),
            alpha: UIColorMasks.alphaValue(c)
        )
    }
    
    convenience init(hexLight: String?, hexDark: String?) {
        self.init { traitCollection -> UIColor in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return hexDark != nil ? .init(hex: hexDark) : .init(hex: hexLight)
            case .light, .unspecified:
                return .init(hex: hexLight)
            @unknown default:
                return .init(hex: hexLight)
            }
        }
    }
    
    var hex: String { hexDescription(false) }
    var hexWithAlpha: String { hexDescription(true) }

    fileprivate func hexDescription(_ includeAlpha: Bool = false) -> String {
        guard cgColor.numberOfComponents == 4 else {
            return "Color not RGB."
        }
        let a = cgColor.components!.map { Int($0 * CGFloat(255)) }
        let color = String.init(format: "%02x%02x%02x", a[0], a[1], a[2])
        if includeAlpha {
            let alpha = String.init(format: "%02x", a[3])
            return "\(color)\(alpha)"
        }
        return color
    }
    
    fileprivate enum UIColorMasks: UInt64 {
        case redMask    = 0xff000000
        case greenMask  = 0x00ff0000
        case blueMask   = 0x0000ff00
        case alphaMask  = 0x000000ff
        
        static func redValue(_ value: UInt64) -> CGFloat {
            CGFloat((value & redMask.rawValue) >> 24) / 255.0
        }
        
        static func greenValue(_ value: UInt64) -> CGFloat {
            CGFloat((value & greenMask.rawValue) >> 16) / 255.0
        }
        
        static func blueValue(_ value: UInt64) -> CGFloat {
            CGFloat((value & blueMask.rawValue) >> 8) / 255.0
        }
        
        static func alphaValue(_ value: UInt64) -> CGFloat {
            CGFloat(value & alphaMask.rawValue) / 255.0
        }
    }
    
    fileprivate static func normalize(_ hex: String?) -> String {
        guard var hexString = hex else {
            return "00000000"
        }
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }
        if hexString.count == 3 || hexString.count == 4 {
            hexString = hexString.map { "\($0)\($0)" } .joined()
        }
        let hasAlpha = hexString.count > 7
        if !hasAlpha {
            hexString += "ff"
        }
        return hexString
    }
}
