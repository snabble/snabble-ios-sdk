//
//  L10n.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

extension Snabble {
    public static func l10n(_ key: String, _ table: String? = nil, _ value: String? = nil) -> String {
        Assets.localizedString(forKey: key, table: table, value: value)
    }
}
