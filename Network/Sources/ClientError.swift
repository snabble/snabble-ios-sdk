//
//  ClientError.swift
//
//
//  Created by Uwe Tilemann on 20.02.24.
//

import Foundation

public struct ClientError: Decodable, Sendable {
    public let type: String
    public let message: String
    public let validations: [Validation]?
    
    public struct Validation: Decodable, Sendable {
        public let field: String
        public let category: String
        public let restrictions: [Restriction]

        enum CodingKeys: CodingKey {
            case field
            case category
            case restrictions
        }

        public struct Restriction: Decodable, Sendable {
            public let possibleValues: [String]?
            public let min: Int?
            public let max: Int?
        }
    }
    
    private enum CodingKeys: CodingKey {
        case type
        case message
        case validationErrors
    }
    
    private enum ErrorKey: CodingKey {
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: ErrorKey.self)
        let container = try topLevelContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        self.type = try container.decode(String.self, forKey: .type)
        self.message = try container.decode(String.self, forKey: .message)
        self.validations = try container.decodeIfPresent([Validation].self, forKey: .validationErrors)
    }
}
