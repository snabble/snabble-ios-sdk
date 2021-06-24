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

    @IBOutlet private var imageWidth: NSLayoutConstraint!
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

        checkImage.image = UIImage.fromBundle("icon-check-large")

        if #available(iOS 13.0, *) {
            spinner.style = .medium
        }

        nameLabel.textColor = .label
        quantityLabel.textColor = .label

        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        task?.cancel()
        task = nil
        productImage.image = nil
        imageWidth.constant = 10
        spinner.isHidden = true

        item = nil
        checked = false

        quantityLabel.text = nil
        nameLabel.text = nil
    }

    func setListItem(_ item: ShoppingListItem, _ list: ShoppingList) {
        self.item = item
        let quantity: String?

        imageWidth.constant = list.hasImages ? 42 : 10

        switch item.entry {
        case .product(let product):
            quantity = "\(item.quantity)"
            loadImage(url: product.imageUrl)
        case .tag, .custom:
            quantity = nil
        }

        quantityLabel.text = quantity
        checkImage.isHidden = !item.checked

        let alpha: CGFloat = item.checked ? 0.3 : 1
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

    private func loadImage(url: String?) {
        guard
            let imgUrl = url,
            let url = URL(string: imgUrl)
        else {
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

            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    ShoppingListCell.imageCache[imgUrl] = image
                    self.productImage.image = image
                }
            }
        }
        self.task?.resume()
    }
}
