//
//  OnboardingViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import Combine

/// OnboardingViewModel describing the Onboading configuration
public final class OnboardingViewModel: ObservableObject, Decodable {
    public static let `default`: OnboardingViewModel = loadJSON("OnboardingData.json")

    /// the configuration like `imagesource` and `hasPageControl` to enable page swiping
    public let configuration: OnboardingConfiguration
    /// All items to be shown in Onboarding
    public let items: [OnboardingItem]

    var numberOfPages: Int {
        items.count
    }

    /// Current shown item
    @Published public var item: OnboardingItem? {
        didSet {
            guard let item = item else {
                return currentPage = 0
            }
            currentPage = items.index(of: item) ?? 0
        }
    }
    /// Switched to `true` as soon as onboarding is completed.
    /// - Important: You are responsible to dismiss the associated view
    @Published public var isDone: Bool = false

    /// Current shown page
    @Published public var currentPage: Int = 0

    @discardableResult
    func next(for element: OnboardingItem) -> OnboardingItem? {
        guard let item = items.next(after: element) else {
            isDone = true
            return nil
        }
        self.item = item
        return item
    }

    @discardableResult
    func previous(for element: OnboardingItem) -> OnboardingItem? {
        guard let item = items.previous(before: element) else {
            return nil
        }
        self.item = item
        return item
    }

    enum CodingKeys: String, CodingKey {
        case items
        case configuration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.configuration = try container.decode(OnboardingConfiguration.self, forKey: .configuration)
        self.items = try container.decode([OnboardingItem].self, forKey: .items)
        self.item = items.first
    }
}

private extension Array where Element: Equatable {
    func next(after element: Element) -> Element? {
        guard let index = index(of: element) else {
            return nil
        }
        var nextIndex = index + 1
        guard indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }

    func previous(before element: Element) -> Element? {
        guard let index = index(of: element) else {
            return nil
        }
        var nextIndex = index - 1
        guard nextIndex >= 0, indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }
}
