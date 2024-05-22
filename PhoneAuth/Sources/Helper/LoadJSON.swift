//
//  LoadJSON.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 15.05.23.
//

import Foundation

public func loadJSON<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.module.url(forResource: filename, withExtension: "json") else {
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
