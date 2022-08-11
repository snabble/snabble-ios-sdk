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
    /// `hasPageControl` to enable page swiping
    public let hasPageControl: Bool?
}
