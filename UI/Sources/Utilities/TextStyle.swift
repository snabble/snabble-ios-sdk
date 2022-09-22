//
//  TextStyle.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 01.09.22.
//

import SwiftUI

public enum TextStyle: String {
    case largeTitle
    case title
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption1
    case caption2

    var font: Font {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title, .title1:
            return .title
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .body:
            return .body
        case .callout:
            return .callout
        case .subheadline:
            return .subheadline
        case .footnote:
            return .footnote
        case .caption, .caption1:
            return .caption
        case .caption2:
            return .caption2
        }
    }
}
