//
//  Image+Fallback.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 23.08.22.
//

import Foundation
import SwiftUI

extension SwiftUI.Image {
    static func image(named name: String, systemName: String? = nil) -> SwiftUI.Image {
        Asset.image(named: name) ?? SwiftUI.Image(systemName: systemName ?? name)
    }
}
