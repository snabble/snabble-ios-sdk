//
//  ShoppingListTableViewCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class ShoppingListCell: UITableViewCell {
    private var item: ShoppingListItem?
    private var indexPath: IndexPath?
    private var checked = false

    @IBOutlet private var productImage: UIImageView!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    @IBOutlet private var nameLabel: UILabel!

    @IBOutlet private var quantityLabel: UILabel!
    @IBOutlet private var checkContainer: UIView!
    @IBOutlet private var checkImage: UIImageView!

    private var task: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        checkContainer.layer.shadowColor = UIColor.gray.cgColor
        checkContainer.layer.shadowOpacity = 0.3
        checkContainer.layer.shadowOffset = CGSize.zero
        checkContainer.layer.shadowRadius = 1.5
        checkContainer.layer.masksToBounds = true
        checkContainer.layer.borderWidth = 1 / UIScreen.main.scale
        checkContainer.layer.borderColor = UIColor.systemBackground.cgColor
        checkContainer.layer.cornerRadius = checkContainer.bounds.width / 2
        checkContainer.backgroundColor = .clear

        checkImage.image = Asset.SnabbleSDK.iconCheckLarge.image

        if #available(iOS 13.0, *) {
            spinner.style = .medium
        }

        nameLabel.textColor = .label
        quantityLabel.textColor = .label
        productImage.tintColor = .label

        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        task?.cancel()
        task = nil
        productImage.image = nil
        spinner.isHidden = true

        item = nil
        checked = false

        quantityLabel.text = nil
        nameLabel.text = nil
    }

    func setListItem(_ item: ShoppingListItem, _ list: ShoppingList) {
        self.item = item
        let quantity: String?

        switch item.entry {
        case .product:
            quantity = "\(item.quantity)"
        case .tag:
            quantity = "\(item.quantity)"
        case .custom:
            quantity = nil
        }
        loadImage(for: item)

        quantityLabel.text = quantity
        checkImage.isHidden = !item.checked

        let alpha = item.checked ? 0.3 : 1
        nameLabel.alpha = alpha
        checkContainer.alpha = alpha
        quantityLabel.alpha = alpha

        let strikeStyle: NSUnderlineStyle = item.checked ? .single : []
        let attributes = [NSAttributedString.Key.strikethroughStyle: strikeStyle.rawValue]

        nameLabel.attributedText = NSAttributedString(string: item.name, attributes: attributes)
    }
}

// MARK: - image loading

extension ShoppingListCell {
    private static var imageCache = [String: UIImage]()

    private func loadImage(for item: ShoppingListItem) {
        guard
            let imgUrl = item.product?.imageUrl,
            let url = URL(string: imgUrl)
        else {
            self.setDefaultImage(for: item)
            return
        }

        if let img = ShoppingListCell.imageCache[imgUrl] {
            self.productImage.image = img
            return
        }

        self.spinner.startAnimating()
        self.spinner.isHidden = false
        self.task = URLSession.shared.dataTask(with: url) { data, _, error in
            self.task = nil
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.spinner.isHidden = true
            }
            guard let data = data, error == nil else {
                return
            }

            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    ShoppingListCell.imageCache[imgUrl] = image
                    self.productImage.image = image
                } else {
                    self.setDefaultImage(for: item)
                }
            }
        }
        self.task?.resume()
    }

    private func setDefaultImage(for item: ShoppingListItem) {
        let asset: SwiftGenImageAsset
        switch item.entry {
        case .product:
            asset = Asset.SnabbleSDK.Shoppinglist.shoppinglistIconProduct
        case .tag:
            asset = Asset.SnabbleSDK.Shoppinglist.shoppinglistIconTag
        case .custom:
            asset = Asset.SnabbleSDK.Shoppinglist.shoppinglistIconText
        }

        productImage.image = asset.image.withRenderingMode(.alwaysTemplate)
    }
}
