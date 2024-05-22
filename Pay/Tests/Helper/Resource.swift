//
//  Resource.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import Foundation

public func loadResource(inBundle bundle: Bundle, filename: String, withExtension ext: String?) throws -> Data {
    guard let resourceURL = bundle.url(forResource: filename, withExtension: ext) else {
        throw URLError(.badURL)
    }
    return try Data(contentsOf: resourceURL)
}
