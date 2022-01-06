//
//  DatatransPaymentMethodToken.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Datatrans

extension DatatransPaymentMethodToken {
    init(savedPaymentMethod: SavedPaymentMethod) {
        if let postFinanceToken = savedPaymentMethod as? SavedPostFinanceCard {
            // postfinance card
            self.init(
                alias: postFinanceToken.alias,
                displayTitle: postFinanceToken.displayTitle,
                cardHolder: postFinanceToken.cardholder,
                expiryDate: postFinanceToken.cardExpiryDate
            )
        } else if let cardToken = savedPaymentMethod as? SavedCard {
            // credit card
            self.init(
                alias: cardToken.alias,
                displayTitle: cardToken.displayTitle,
                cardHolder: cardToken.cardholder,
                expiryDate: cardToken.cardExpiryDate
            )
        } else {
            // plain old PaymentMethodToken
            self.init(
                token: savedPaymentMethod.alias,
                displayTitle: savedPaymentMethod.displayTitle,
                cardHolder: nil,
                expirationMonth: nil,
                expirationYear: nil
            )
        }
    }

    private init(alias: String, displayTitle: String, cardHolder: String?, expiryDate: CardExpiryDate?) {
        self.init(
            token: alias,
            displayTitle: displayTitle,
            cardHolder: cardHolder,
            expirationMonth: expiryDate?.formattedMonth,
            expirationYear: expiryDate?.formattedYear
        )
    }
}
