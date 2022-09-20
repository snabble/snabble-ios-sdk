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
    public let padding: Padding?
    
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
        self.padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
    }

    public var stackStyle: StackStyle {
        guard let string = style, let stackStyle = StackStyle(rawValue: string) else {
            return .scroll
        }
        return stackStyle
    }
}
