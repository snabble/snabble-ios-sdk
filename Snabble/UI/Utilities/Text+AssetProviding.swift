//
//  Text+AssetProviding.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 23.08.22.
//

import Foundation
import SwiftUI

extension Text {
    init(key string: String) {
        let value = Asset.localizedString(forKey: string)
        self.init(value)
    }
}
