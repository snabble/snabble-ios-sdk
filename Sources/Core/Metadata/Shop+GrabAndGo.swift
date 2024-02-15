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

    public func includePaymentMethod(_ method: RawPaymentMethod) -> Bool {
        return acceptedPaymentMethods.first(where: { $0 == method }) != nil
    }

    public var acceptedPaymentMethods: [RawPaymentMethod] {
        if isGrabAndGo {
            return [.creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress, .externalBilling]
        } else {
            return Snabble.shared.projects
                .filter { $0.id == projectId }
                .flatMap { $0.paymentMethods }
                .filter { $0.visible }
        }
    }
    
    public var hasAcceptedPaymentMethod: Bool {
        let details = PaymentMethodDetails.read().compactMap({ $0.rawMethod })
        
        return !acceptedPaymentMethods.filter({ details.contains($0) }).isEmpty
    }
}
