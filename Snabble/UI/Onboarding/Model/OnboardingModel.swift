//
//  OnboardingModel.swift
//  Onboarding
//
//  Created by Uwe Tilemann on 05.08.22.
//

import Foundation

#if canImport(Combine)
import Combine

public final class OnboardingModel: ObservableObject, Decodable {
    public static let shared : OnboardingModel = load("onboardingData.json")
    
    @Published var configuration: OnboardingConfiguration
    @Published var items: [OnboardingItem]

    enum CodingKeys: String, CodingKey {
        case items
        case configuration
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.items = try container.decode([OnboardingItem].self, forKey:.items)
        self.configuration = try container.decode(OnboardingConfiguration.self, forKey: .configuration)
    }
}
#endif

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = AssetProvider.shared.url(forResource: filename, withExtension: nil) else {
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
