//
//  OnboardingItem.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation

/// The OnboadingItem holds the info for one page
///
public struct OnboardingItem: Hashable, Codable, Swift.Identifiable, ImageSourcing {
    /// id to fullfil the `Swift.Identifiable` protocol
    public var id = UUID()

    /// optional string for onboarding image
    public let imageSource: String?
    /// optional text description
    public let text: String
    /// defines an optional custom button title
    public let customButtonTitle: String?
    /// optional string to
    public let link: String?

    enum CodingKeys: String, CodingKey {
        case imageSource
        case text
        case customButtonTitle
        case link
    }

    /// convinience init with default nil values for less used properties
    public init(
        imageSource: String? = nil,
        text: String,
        customButtonTitle: String? = nil,
        link: String? = nil
    ) {
        self.imageSource = imageSource
        self.text = text
        self.customButtonTitle = customButtonTitle
        self.link = link
    }
}

import SwiftUI

@available(iOS 15.0, *)
public extension OnboardingItem {
    /// use markdown for links like: `Please visit: [snabble](https://snabble.io)`
    var attributedString: AttributedString {
        do {
            return try AttributedString(markdown: NSLocalizedString(text ?? "", comment: ""), baseURL: nil)
        } catch {
            return AttributedString(NSLocalizedString(text ?? "", comment: ""))
        }
    }
}
