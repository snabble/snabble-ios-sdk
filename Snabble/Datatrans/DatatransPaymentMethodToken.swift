//
//  DatatransPaymentMethodToken.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Datatrans

extension DatatransPaymentMethodToken {
    init(token: PaymentMethodToken) {
        if let postFinanceToken = token as? PostFinanceCardToken {
            // postfinance card
            self.init(token: postFinanceToken.token, displayTitle: postFinanceToken.displayTitle,
                      cardHolder: postFinanceToken.cardholder, expiryDate: postFinanceToken.cardExpiryDate)
        } else if let cardToken = token as? CardToken {
            // credit card
            self.init(token: cardToken.token, displayTitle: cardToken.displayTitle,
                      cardHolder: cardToken.cardholder, expiryDate: cardToken.cardExpiryDate)
        } else {
            // plain old PaymentMethodToken
            self.init(token: token.token, displayTitle: token.displayTitle,
                      cardHolder: nil, expirationMonth: nil, expirationYear: nil)
        }
    }

    private init(token: String, displayTitle: String, cardHolder: String?, expiryDate: CardExpiryDate?) {
        self.init(token: token, displayTitle: displayTitle, cardHolder: cardHolder,
                  expirationMonth: expiryDate?.formattedMonth, expirationYear: expiryDate?.formattedYear)
    }
}
