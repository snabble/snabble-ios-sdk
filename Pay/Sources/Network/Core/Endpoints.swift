//
//  Endpoints.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleNetwork

/// A namespace for types that serve as `Endpoint`.
///
/// The various endpoints defined as extensions on ``Endpoint``.
public enum Endpoints {
    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
