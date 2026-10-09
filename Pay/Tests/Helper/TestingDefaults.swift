//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-22.
//

import Foundation

public enum TestingDefaults {
    nonisolated(unsafe) public static let dateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter
    }()

    public static let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
