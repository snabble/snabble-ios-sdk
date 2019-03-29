//
//  PaymentMethodCell.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

final class PaymentMethodCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!

    var paymentMethod: PaymentMethod = .encodedCodes {
        didSet {
            let image = UIImage.fromBundle(paymentMethod.icon)
            self.icon.image = image
            self.label.text = paymentMethod.displayName

            switch paymentMethod {
            case .teleCashDeDirectDebit(let data):
                if data == nil {
                    self.icon.image = image?.grayscale()
                    self.label.textColor = SnabbleUI.appearance.primaryColor
                    self.label.text = "Snabble.PaymentSelection.addNow".localized()
                }
            default: ()
            }

        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.layer.cornerRadius = 10
        self.containerView.layer.borderColor = UIColor(white: 0, alpha: 0.25).cgColor
        self.containerView.layer.borderWidth = 1 / UIScreen.main.scale
        self.containerView.layer.masksToBounds = true

        self.label.text = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.label.textColor = nil
    }
}


