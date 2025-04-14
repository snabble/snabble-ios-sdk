//
//  Asset+Style.swift
//  Snabble
//
//  Created by Uwe Tilemann on 08.04.25.
//

import SwiftUI

extension Shape {
    public static func shape(domain: Any?) -> (any SwiftUI.Shape) {
        return Asset.shape(domain: domain) ?? RoundedRectangle(cornerRadius: 8)
    }
}
