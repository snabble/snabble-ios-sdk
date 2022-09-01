//
//  TextStyle.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 01.09.22.
//

import SwiftUI

public enum TextStyle: String {
    case body
    case footnote
    case headline
    case title

    var font: Font {
        switch self {
        case .body:
            return .body
        case .footnote:
            return .footnote
        case .headline:
            return .headline
        case .title:
            return .title
        }
    }
}
