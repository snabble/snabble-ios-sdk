//
//  Endpoint+Snabble.swift
//

import Foundation

extension Endpoint {
    /// Resolves the endpoint against the base URL of `domain` and, if given, authorizes it with a bearer `token`.
    func applying(domain: Domain, token: Token? = nil) -> Endpoint<Response> {
        var copy = self
        copy.baseURL = domain.baseURL
        copy.headerFields = domain.headerFields.merging(headerFields, uniquingKeysWith: { _, new in new })
        if let token {
            copy.headerFields["Authorization"] = "Bearer \(token.value)"
        }
        return copy
    }
}
