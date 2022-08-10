//
//  OnboardingConfiguration.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 06.08.22.
//

import Foundation

public struct OnboardingConfiguration : Decodable, ImageSourcing {
    public let imageSource: String?
    public let hasPageControl: Bool?
}

