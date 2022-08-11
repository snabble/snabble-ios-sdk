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
    public static let shared: OnboardingModel = load("onboardingData.json")

    /// the configuration like `imagesource` and `hasPageControl` to enable page swiping
    @Published var configuration: OnboardingConfiguration
    @Published var items: [OnboardingItem]

    enum CodingKeys: String, CodingKey {
        case items
        case configuration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.items = try container.decode([OnboardingItem].self, forKey: .items)
        self.configuration = try container.decode(OnboardingConfiguration.self, forKey: .configuration)
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Assets.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
