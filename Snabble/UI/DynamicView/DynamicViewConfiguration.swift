//
//  DynamicStackConfiguration.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import SwiftUI

public struct DynamicViewConfiguration: Decodable, ImageSourcing {
    public let imageSource: String?
    public let style: String?
    public let spacing: CGFloat?
    public let padding: EdgeInsets
    
    let shadowRadius: CGFloat = 8
    
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageSource = try container.decodeIfPresent(String.self, forKey: .imageSource)
        self.style = try container.decodeIfPresent(String.self, forKey: .style)
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        if let padding = try container.decodeIfPresent(Array<CGFloat>.self, forKey: .padding) {
            switch padding.count {
            case 1:
                self.padding = .init(top: padding[0], leading: padding[0], bottom: padding[0], trailing: padding[0])
            case 2:
                self.padding = .init(top: padding[1], leading: padding[0], bottom: padding[1], trailing: padding[0])
            case 4:
                self.padding = .init(top: padding[1], leading: padding[0], bottom: padding[2], trailing: padding[3])
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.padding], debugDescription: "invalid number of values"))
            }
        } else {
            padding = .init()
        }

    }

    public var stackStyle: StackStyle {
        guard let string = style, let stackStyle = StackStyle(rawValue: string) else {
            return .scroll
        }
        return stackStyle
    }
}
