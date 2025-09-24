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
import Observation

public enum Onboarding {
    private static let checkKey = "io.snabble.onboarding.wasPerformed"
    
    /// check if Onboarding must be performed
    public static var isRequired: Bool {
        return UserDefaults.standard.bool(forKey: checkKey) == false
    }
    static func wasPerformed() {
        UserDefaults.standard.set(true, forKey: checkKey)
    }
}

/// OnboardingViewModel describing the Onboading configuration
@Observable
public final class OnboardingViewModel: Codable {
    /// the configuration
    public let configuration: OnboardingConfiguration
    /// All items to be shown in Onboarding
    public let items: [OnboardingItem]

    var numberOfPages: Int {
        items.count
    }

    public init(
        configuration: OnboardingConfiguration,
        items: [OnboardingItem]
    ) {
        self.configuration = configuration
        self.items = items
        self.item = items.first
    }

    enum CodingKeys: String, CodingKey {
        case items
        case configuration
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let configuration = try container.decode(OnboardingConfiguration.self, forKey: .configuration)
        let items = try container.decode([OnboardingItem].self, forKey: .items)
        self.init(configuration: configuration, items: items)
    }

    /// Current shown item
    public var item: OnboardingItem? {
        didSet {
            guard let item = item else {
                return currentPage = 0
            }
            currentPage = items.firstIndex(of: item) ?? 0
        }
    }
    /// Switched to `true` as soon as onboarding is completed.
    /// - Important: You are responsible to dismiss the associated view
    public var isDone: Bool = false {
        didSet {
            if isDone {
                Onboarding.wasPerformed()
            }
        }
    }

    /// Current shown page
    public var currentPage: Int = 0

    func isLast(item: OnboardingItem) -> Bool {
        items.last == item
    }

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
}

private extension Array where Element: Equatable {
    func next(after element: Element) -> Element? {
        guard let index = firstIndex(of: element) else {
            return nil
        }
        let nextIndex = index + 1
        guard indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }

    func previous(before element: Element) -> Element? {
        guard let index = firstIndex(of: element) else {
            return nil
        }
        let nextIndex = index - 1
        guard nextIndex >= 0, indices.contains(nextIndex) else {
            return nil
        }
        return self[nextIndex]
    }
}
