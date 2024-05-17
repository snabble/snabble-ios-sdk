//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 16.05.24.
//

import SwiftUI

extension SwiftUI.Font {
    public static func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> SwiftUI.Font? {
        return Asset.font(name, size: size, relativeTo: textStyle, domain: domain)
    }
}

