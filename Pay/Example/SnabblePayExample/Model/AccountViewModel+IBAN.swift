//
//  AccountViewModel+IBAN.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 04.04.23.
//

import Foundation

extension String {
    func prettyPrint(template placeholder: String) -> String {
        let normalized = self.replacingOccurrences(of: " ", with: "")
        
        guard placeholder.replacingOccurrences(of: " ", with: "").count == normalized.count else {
            return self
        }
        
        var offset: Int = 0
        let start = placeholder.index(placeholder.startIndex, offsetBy: 0)
        var result = String()
        
        for char in String(placeholder[start...]) {
            if char == " " {
                result.append(" ")
            } else {
                let currentIndex = normalized.index(normalized.startIndex, offsetBy: offset)
                result.append(String(normalized[currentIndex]))
                offset += 1
            }
        }
        return result
    }
}

extension AccountViewModel {
    var ibanString: String {
        let iban = account.iban.rawValue.replacingOccurrences(of: "*", with: "•")
        return iban.prettyPrint(template: "DEpp bbbb bbbb kkkk kkkk kk")
    }
}
