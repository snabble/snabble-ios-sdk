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

    public var paymentsMethods: [RawPaymentMethod] {
        return Snabble.shared.projects
            .filter { $0.id == projectId }
            .flatMap { $0.paymentMethods }
            .filter { $0.visible && excludePaymentMethod($0) == false }
    }

    public var hasAcceptedPaymentMethod: Bool {
        let details = PaymentMethodDetails.read().compactMap({ $0.rawMethod })
        
        return !paymentsMethods.filter({ details.contains($0) }).isEmpty
    }
}
