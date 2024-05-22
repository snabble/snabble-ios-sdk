//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-22.
//

import Foundation

public enum TestingDefaults {
    public static var dateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter
    }()

    public static var jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
