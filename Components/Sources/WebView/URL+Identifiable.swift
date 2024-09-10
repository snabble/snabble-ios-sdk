//
//  URL+Identifiable.swift
//  SnabbleComponents
//
//  Created by Andreas Osberghaus on 2024-09-05.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: URL { self }
}
