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

        self.containerView.addCornersAndShadow(backgroundColor: .white, cornerRadius: 5)
        self.containerView.layer.shadowColor = UIColor.darkGray.cgColor
        self.label.text = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.containerView.backgroundColor = .white
        self.label.textColor = nil
    }
}


