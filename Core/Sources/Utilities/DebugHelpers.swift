//
//  DebugHelpers.swift
//  
//
//  Created by Uwe Tilemann on 29.07.24.
//

import Foundation

extension Data {
    public func printAsJSON() {
        if let theJSONData = try? JSONSerialization.jsonObject(with: self, options: []) as? NSDictionary {
            var swiftDict: [String: Any] = [:]
            for key in theJSONData.allKeys {
                let stringKey = key as? String
                if let key = stringKey, let keyValue = theJSONData.value(forKey: key) {
                    swiftDict[key] = keyValue
                }
            }
            swiftDict.printAsJSON()
        }
    }
}

extension Dictionary {
    func printAsJSON() {
        if let theJSONData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted),
           let theJSONText = String(data: theJSONData, encoding: .utf8) {
            print("\(theJSONText)")
        }
    }
}
