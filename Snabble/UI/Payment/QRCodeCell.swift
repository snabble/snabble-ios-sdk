//
//  QRCodeCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class QRCodeCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.image = nil
    }

    func setImage(_ image: UIImage?) {
        self.imageView.image = image
        self.imageWidth.constant = image?.size.width ?? 0
    }
}
