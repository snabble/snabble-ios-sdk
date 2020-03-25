//
//  MethodSelectionCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class MethodSelectionCell: UITableViewCell {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var useLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setMethod(_ method: RawPaymentMethod, _ useableAt: String?) {
        self.icon.image = method.icon
        self.nameLabel.text = method.displayName
        self.useLabel.text = useableAt
    }
}
