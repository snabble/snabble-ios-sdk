//
//  OnboardingConfiguration.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SwiftUI

import SnabbleTheme

public struct OnboardingConfiguration: Codable, ImageSourcing {
    /// optional string of onboarding image logo to display
    public let imageSource: String?

    public init(imageSource: String?) {
        self.imageSource = imageSource
    }
}
