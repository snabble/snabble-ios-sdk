//
//  QRCodeCell.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

final class QRCodeCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.image = nil
    }
}
