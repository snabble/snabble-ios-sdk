//
//  Sequence+KeyPathSorted.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

extension Sequence {
    func sorted<Value>(
        by keyPath: KeyPath<Self.Element, Value>,
        using valuesAreInIncreasingOrder: (Value, Value) throws -> Bool
    ) rethrows -> [Self.Element] {
        return try sorted(by: {
            try valuesAreInIncreasingOrder($0[keyPath: keyPath], $1[keyPath: keyPath])
        })
    }

    func sorted<Value: Comparable>(
        by keyPath: KeyPath<Self.Element, Value>
    ) -> [Self.Element] {
        return sorted(by: keyPath, using: <)
    }

}
