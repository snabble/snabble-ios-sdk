//
//  ClientError.swift
//
//
//  Created by Uwe Tilemann on 20.02.24.
//

import Foundation

public struct ClientError: Decodable {
    public let type: String?
    public let message: String?
    public let validationErrors: [Validation]?
    
    private enum CodingKeys: CodingKey {
        case type
        case message
        case validationErrors
    }
    public struct Validation: Decodable {
        public let field: String
        public let category: String
        
        enum CodingKeys: CodingKey {
            case field
            case category
        }
    }
    private enum ErrorKey: CodingKey {
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: ErrorKey.self)
        let container = try topLevelContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.validationErrors = try container.decodeIfPresent([Validation].self, forKey: .validationErrors)
    }
}
