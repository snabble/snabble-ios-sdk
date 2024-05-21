//
//  String+Localization.swift
//
//
//  Created by Andreas Osberghaus on 2024-05-21.
//

import Foundation

public extension String {
    static func localizedStringWithArguments(_ arguments: CVarArg..., forKey key: String, table: String? = nil, value: String? = nil) -> String {
        let format = Bundle.main.localizedString(forKey: key, value: value, table: table)
        return String.localizedStringWithFormat(format, arguments)
    }

    func localizedWithArguments(_ arguments: CVarArg..., table: String? = nil, value: String? = nil) -> String {
        let format = Bundle.main.localizedString(forKey: self, value: value, table: table)
        return String.localizedStringWithFormat(format, arguments)
    }
}
