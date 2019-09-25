//
//  PaymentMethodCell.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

final class PaymentMethodCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!

    var paymentMethod: PaymentMethod = .qrCodeOffline {
        didSet {
            let image = UIImage.fromBundle(paymentMethod.icon)
            self.icon.image = image
            self.label.text = paymentMethod.displayName

            let incomplete: Bool
            switch paymentMethod {
            case .deDirectDebit(let data), .visa(let data), .mastercard(let data):
                incomplete = data == nil

            case .qrCodePOS, .qrCodeOffline:
                incomplete = false
            }

            if incomplete {
                self.icon.image = image?.grayscale()
                self.label.textColor = SnabbleUI.appearance.primaryColor
                self.label.text = "Snabble.PaymentSelection.addNow".localized()
            }
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
    }

    private var borderColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label.withAlphaComponent(0.25)
        } else {
            return UIColor(white: 0, alpha: 0.25)
        }
    }
}


