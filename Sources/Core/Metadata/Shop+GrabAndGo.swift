//
//  Shop+GrabAndGo.swift
//  
//
//  Created by Andreas Osberghaus on 2023-08-24.
//

/// extension for shop that adds Grab&Go-based stuff
extension Shop {
    public var isGrabAndGo: Bool {
        guard let flag = external?["grabAndGoEnabled"] as? Bool else {
            return false
        }
        return flag
    }
    
    public func excludePaymentMethod(_ method: RawPaymentMethod) -> Bool {
        return isGrabAndGo && method == .giropayOneKlick
    }
}
