//
//  DynamicStackConfiguration.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public struct DynamicViewConfiguration: Decodable, ImageSourcing {
    public let imageSource: String?
    public let style: String?
    public let spacing: CGFloat?
    public let padding: CGFloat?
    
    enum CodingKeys: String, CodingKey {
        case imageSource = "image"
        case style
        case spacing
        case padding
    }
    
    public enum StackStyle: String {
        case scroll
        case list
    }

    public var stackStyle: StackStyle {
        guard let string = style, let stackStyle = StackStyle(rawValue: string) else {
            return .scroll
        }
        return stackStyle
    }
}
