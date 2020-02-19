//
//  PaymentMethodCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

extension PaymentMethodDetail {
    var icon: UIImage? {
        switch methodData.self {
        case .sepa:
            return UIImage.fromBundle("SnabbleSDK/payment-small-sepa")
        case .creditcard(let creditcardData):
            switch creditcardData.brand {
            case .visa: return UIImage.fromBundle("SnabbleSDK/payment-small-visa")
            case .mastercard: return UIImage.fromBundle("SnabbleSDK/payment-small-mastercard")
            }
        case .tegutEmployeeCard:
            return UIImage.fromBundle("SnabbleSDK/payment-small-tegut")
        }
    }
}

final class PaymentMethodCell: UITableViewCell {

    @IBOutlet private weak var name: UILabel!
    @IBOutlet private weak var useLabel: UILabel!
    @IBOutlet private weak var icon: UIImageView!

    func setDetail(_ detail: PaymentMethodDetail, _ projectNames: [String]?) {
        self.name.text = detail.displayName
        self.icon.image = detail.icon

        if let names = projectNames, !names.isEmpty {
            let retailers = names.joined(separator: ", ")
            let fmt = "Snabble.Payment.usableAt".localized()
            self.useLabel.text = String(format: fmt, retailers)
        } else {
            self.useLabel.text = " "
        }

        if detail.originType == .tegutEmployeeID {
            self.accessoryType = .none
        } else {
            self.accessoryType = .disclosureIndicator
        }
    }
}
