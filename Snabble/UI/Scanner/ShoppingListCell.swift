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
    private var task: URLSessionDataTask?

    private weak var cellView: ShoppingListCellView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupUI()
        prepareForReuse()
    }

    public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = .clear

        let cellView = ShoppingListCellView(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(cellView)

        self.cellView = cellView

        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
            cellView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        task?.cancel()
        task = nil
        item = nil
        checked = false
        self.cellView?.prepareForReuse()
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

        let strikeStyle: NSUnderlineStyle = item.checked ? .single : []
        let attributes = [NSAttributedString.Key.strikethroughStyle: strikeStyle.rawValue]

        self.cellView?.configure(with: NSAttributedString(string: item.name, attributes: attributes),
                                 item.checked,
                                 quantity)
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
            self.cellView?.configureProductImage(with: img)
            return
        }

        self.cellView?.spinner?.startAnimating()
        self.task = Snabble.urlSession.dataTask(with: url) { data, _, error in
            self.task = nil
            DispatchQueue.main.async {
                self.cellView?.spinner?.stopAnimating()
            }
            guard let data = data, error == nil else {
                return
            }

            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    ShoppingListCell.imageCache[imgUrl] = image
                    self.cellView?.configureProductImage(with: image)
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

        self.cellView?.configureProductImage(with: asset.image.withRenderingMode(.alwaysTemplate))
    }
}
