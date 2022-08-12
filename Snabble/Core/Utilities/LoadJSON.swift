//
//  LoadJSON.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.08.22.
//

import Foundation

/// Global function to initialize any `Decodable` object from a JSON file
///
///     /// Create a shared instance with '{ "hello": "world" }'
///     struct MyWorld: Decodable {
///         static shared: MyWorld = LoadJSON("MyWorld.json")
///
///         let hello: String?
///     }
///     
/// - Parameter filename : The filename to load.
///
/// - Returns: An initialized decodable object
///
/// - Important: If the file `filename` does not exists or contains corrupt JSON data this function throws an `fatalError()`
func LoadJSON<T: Decodable>(_ filename: String) -> T {
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
