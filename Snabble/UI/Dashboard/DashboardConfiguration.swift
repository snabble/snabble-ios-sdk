//
//  DashboardConfiguration.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public struct DashboardConfiguration: Codable, ImageSourcing {
    public let imageSource: String?

    enum CodingKeys: String, CodingKey {
        case imageSource = "image"
    }
}
