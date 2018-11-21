//
//  PaymentMethodCell.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class PaymentMethodCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.makeRoundedButton(cornerRadius: 5)
        self.containerView.layer.shadowColor = UIColor.darkGray.cgColor
        self.label.text = nil
    }
    
}
