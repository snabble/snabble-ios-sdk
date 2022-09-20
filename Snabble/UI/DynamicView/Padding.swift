//
//  Padding.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 20.09.22.
//

import Foundation

public struct Padding: Decodable {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer().decode(Array<CGFloat>.self)
            switch container.count {
            case 1:
                top = container[0]
                leading = container[0]
                bottom = container[0]
                trailing = container[0]
            case 2:
                top = container[1]
                leading = container[0]
                bottom = container[1]
                trailing = container[0]
            case 4:
                top = container[1]
                leading = container[0]
                bottom = container[2]
                trailing = container[3]
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "invalid number of values"))
            }
        }
    }
}

import SwiftUI

extension Padding {
    public var edgeInsets: EdgeInsets {
        .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}
