//
//  OnboardingModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import Combine

/// OnboardingModel describing the Onboading configuration
public final class OnboardingModel: ObservableObject, Decodable {
    public static let shared: OnboardingModel = loadJSON("OnboardingData.json")

    /// the configuration like `imagesource` and `hasPageControl` to enable page swiping
    @Published var configuration: OnboardingConfiguration
    @Published var items: [OnboardingItem]

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
