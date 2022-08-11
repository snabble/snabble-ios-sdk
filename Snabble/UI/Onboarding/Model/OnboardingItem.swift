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
    public let id: Int
    
    /// optional title string
    public let title: String?
    /// optional string for onboarding image
    public let imageSource: String?
    /// optional text description
    public let text: String?
    /// optional title for the button to show previous onboarding item
    public let prevButtonTitle: String?
    /// optional title for the button to show next onboarding item
    public let nextButtonTitle: String?
    /// optional string to
    public let link: String?

    /// enum for all possible footer configurations
    public enum FooterType {
        case none
        case onlyLeft
        case onlyRight
        case both
    }
    public var footerType: FooterType {
        if prevButtonTitle == nil, nextButtonTitle == nil {
            return .none
        } else if prevButtonTitle != nil, nextButtonTitle == nil {
            return .onlyLeft
        } else if nextButtonTitle != nil, prevButtonTitle == nil {
            return .onlyRight
        } else {
            return .both
        }
    }

    /// convinience init with default nil values for less used properties
    public init(id: Int, title: String? = nil, imageSource: String?, text: String?, prevButtonTitle: String? = nil, nextButtonTitle: String? = nil, link: String? = nil) {
        self.id = id
        self.title = title
        self.imageSource = imageSource
        self.text = text
        self.prevButtonTitle = prevButtonTitle
        self.nextButtonTitle = nextButtonTitle
        self.link = link
    }
}

import SwiftUI

@available(iOS 15.0, *)
public extension OnboardingItem {
    /// use markdown for links like: `Please visit: [snabble](https://snabble.io)`
    var attributedString: AttributedString {
        do {
            return try AttributedString(markdown: self.text ?? "", baseURL: nil)
        } catch {
            return AttributedString(self.text ?? "")
        }
    }
}
