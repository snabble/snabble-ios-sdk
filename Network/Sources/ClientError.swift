//
//  ClientError.swift
//
//
//  Created by Uwe Tilemann on 20.02.24.
//

import Foundation

public struct ClientError: Decodable {
    public let type: String
    public let message: String
    
    private enum CodingKeys: CodingKey {
        case type
        case message
    }
    
    private enum ErrorKey: CodingKey {
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: ErrorKey.self)
        let container = try topLevelContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        self.type = try container.decode(String.self, forKey: .type)
        self.message = try container.decode(String.self, forKey: .message)
    }
}
