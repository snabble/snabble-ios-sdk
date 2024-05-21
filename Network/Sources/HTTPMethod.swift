//
//  HTTPMethod.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

public enum HTTPMethod: Equatable {
    case get([URLQueryItem]?)
    case patch(Data?)
    case post(Data?)
    case put(Data?)
    case delete
    case head

    var value: String {
        switch self {
        case .get: return "GET"
        case .patch: return "PATCH"
        case .put: return "PUT"
        case .post: return "POST"
        case .delete: return "DELETE"
        case .head: return "HEAD"
        }
    }
}
