//
//  URL+StringLiteral.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self = URL(string: "\(value)")!
    }
}
