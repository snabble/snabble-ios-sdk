//
//  DynamicStackConfiguration.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public struct DynamicStackConfiguration: Codable, ImageSourcing {
    public let imageSource: String?
    public let spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case imageSource = "image"
        case spacing
    }
}
