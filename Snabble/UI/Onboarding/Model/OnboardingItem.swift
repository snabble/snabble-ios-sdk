//
//  OnboardingItem.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 05.08.22.
//
import Foundation

/// The OnboadingItem holds the info for one page
///
public struct OnboardingItem : Hashable, Codable, Swift.Identifiable, ImageSourcing {
    public let id: Int
    public let title: String?
    public let imageSource: String?
    public let text: String?
    public let prevButtonTitle: String?
    public let nextButtonTitle: String?
    public let link: String?

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

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15.0, *)
public extension OnboardingItem {
    var attributedString: AttributedString {
        do {
            return try AttributedString(markdown: self.text ?? "", baseURL: nil)
        } catch {
            return AttributedString(self.text ?? "")
        }
    }
}
#endif
