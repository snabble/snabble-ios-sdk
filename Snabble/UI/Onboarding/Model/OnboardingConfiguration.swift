//
//  OnboardingConfiguration.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation

public struct OnboardingConfiguration: Decodable, ImageSourcing {
    /// optional string of onboarding image logo to display
    public let imageSource: String?
    /// `hasPageControl` to enable page swiping. Default value is `true`
    public let hasPageControl: Bool

    /// Decodable CodingKeys
    enum CodingKeys: String, CodingKey {
        case imageSource
        case hasPageControl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageSource = try container.decodeIfPresent(String.self, forKey: .imageSource)
        hasPageControl = try container.decodeIfPresent(Bool.self, forKey: .hasPageControl) ?? true
    }

    public init(imageSource: String?, hasPageControl: Bool = true) {
        self.imageSource = imageSource
        self.hasPageControl = hasPageControl
    }
}
