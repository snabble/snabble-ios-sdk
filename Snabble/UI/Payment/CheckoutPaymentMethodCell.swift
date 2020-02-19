//
//  CheckoutPaymentMethodCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class CheckoutPaymentMethodCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var centerYOffset: NSLayoutConstraint!

    var paymentMethod: PaymentMethod = .qrCodeOffline {
        didSet {
            let image = UIImage.fromBundle(paymentMethod.icon)
            self.icon.image = image
            self.label.text = paymentMethod.displayName

            let incomplete: Bool
            switch paymentMethod {
            case .deDirectDebit(let data), .visa(let data), .mastercard(let data), .externalBilling(let data):
                incomplete = data == nil

            case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
                incomplete = false
            }

            if incomplete {
                self.icon.image = image?.grayscale()
                self.label.textColor = SnabbleUI.appearance.primaryColor
                self.label.text = "Snabble.PaymentSelection.addNow".localized()
            }

            self.centerYOffset.constant = self.label.text == nil ? 0 : -10
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.layer.cornerRadius = 10
        self.containerView.layer.borderColor = self.borderColor.cgColor
        self.containerView.layer.borderWidth = 1 / UIScreen.main.scale
        self.containerView.layer.masksToBounds = true

        self.label.text = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.label.textColor = nil
        
        self.containerView.layer.borderColor = self.borderColor.cgColor
    }

    private var borderColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.separator
        } else {
            return UIColor(white: 0, alpha: 0.25)
        }
    }
}


