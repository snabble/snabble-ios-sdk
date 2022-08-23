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
    let configuration: OnboardingConfiguration
    let items: [OnboardingItem]

    var numberOfPages: Int {
        items.count
    }

    @Published var item: OnboardingItem?
    @Published var isDone: Bool = false

    @discardableResult
    func next(for index: Int) -> OnboardingItem? {
        guard let item = items.next(after: index) else {
            isDone = true
            return nil
        }
        self.item = item
        return item
    }

    @discardableResult
    func previous(for index: Int) -> OnboardingItem? {
        guard let item = items.previous(before: index) else {
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
    }
}

private extension Array where Element: Equatable {
    func next(after index: Int) -> Element? {
        var nextIndex = index + 1
        guard indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }

    func previous(before index: Int) -> Element? {
        var nextIndex = index - 1
        guard nextIndex >= 0, indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }
}
