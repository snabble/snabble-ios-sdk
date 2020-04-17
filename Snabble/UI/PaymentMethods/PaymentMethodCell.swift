//
//  PaymentMethodCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

extension PaymentMethodDetail {
    var icon: UIImage? {
        switch self.methodData {
        case .tegutEmployeeCard:
            return UIImage.fromBundle("SnabbleSDK/payment/payment-tegut")
        default:
            return self.rawMethod.icon
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
            self.useLabel.text = nil
        }

        if detail.originType == .tegutEmployeeID {
            self.accessoryType = .none
        } else {
            self.accessoryType = .disclosureIndicator
        }
    }
}
