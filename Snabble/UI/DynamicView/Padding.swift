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

    enum CodingKeys: String, CodingKey {
        case top
        case leading
        case left
        case bottom
        case trailing
        case right
    }

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
        } catch DecodingError.dataCorrupted(let context) {
            throw DecodingError.dataCorrupted(context)
        } catch {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            top = try container.decodeIfPresent(CGFloat.self, forKey: .top) ?? 0
            leading = try container.decodeIfPresent(CGFloat.self, forKey: .leading) ?? container.decodeIfPresent(CGFloat.self, forKey: .left) ?? 0
            bottom = try container.decodeIfPresent(CGFloat.self, forKey: .bottom) ?? 0
            trailing = try container.decodeIfPresent(CGFloat.self, forKey: .trailing) ?? container.decodeIfPresent(CGFloat.self, forKey: .right) ?? 0
        }
    }
}

import SwiftUI

extension Padding {
    public var edgeInsets: EdgeInsets {
        .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}
