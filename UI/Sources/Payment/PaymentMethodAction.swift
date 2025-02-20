//
//  PaymentMethodAction.swift
//  Snabble
//
//  Created by Uwe Tilemann on 20.02.25.
//

import UIKit

import SnabbleCore

struct PaymentMethodAction: PaymentPovider {
    let title: NSAttributedString
    let item: PaymentMethodItem
    
    init(title: NSAttributedString, item: PaymentMethodItem) {
        self.title = title
        self.item = item
    }

    var method: SnabbleCore.RawPaymentMethod { item.method }
    var methodDetail: SnabbleCore.PaymentMethodDetail? { item.methodDetail }
    var selectable: Bool { item.selectable }
    var active: Bool { item.active }
}

extension Project {
    func paymentActions(for consumer: PaymentConsumer? = nil) -> [PaymentMethodAction] {
        // combine all payment methods of all projects
        let items = paymentItems(for: consumer?.supportedPayments)
        
        let actions = items.map { item in
            let title = Self.attributedString(
                forText: item.title,
                withSubtitle: item.subtitle,
                inColor: (item.active) ? .label : .secondaryLabel
            )
            return PaymentMethodAction(title: title, item: item)
        }
        
        return actions
    }

    private static func attributedString(forText text: String, 
                                         withSubtitle subtitle: String? = nil,
                                         inColor textColor: UIColor) -> NSAttributedString {

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: textColor
        ]

        let newline = subtitle != nil ? "\n" : ""
        let title = NSMutableAttributedString(string: "\(text)\(newline)", attributes: titleAttributes)

        if let subtitle = subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subTitle = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
            title.append(subTitle)
        }

        return title
    }
}
