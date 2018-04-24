//
//  PaymentMethodCell.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class PaymentMethodCell: UICollectionViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.makeRoundedButton(cornerRadius: 5)
    }
    
}
