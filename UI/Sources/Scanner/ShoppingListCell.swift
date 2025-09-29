//
//  ShoppingListTableViewCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

final class ShoppingListCell: UITableViewCell {
    private var task: URLSessionDataTask?

    private weak var cellView: ShoppingListCellView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let cellView = ShoppingListCellView(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        contentView.addSubview(cellView)
        self.cellView = cellView

        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
            cellView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        task?.cancel()
        task = nil
        cellView?.prepareForReuse()
    }

    func configure(with item: ShoppingListItem, in list: ShoppingList) {
        let quantity: String?

        switch item.entry {
        case .product, .tag:
            quantity = "\(item.quantity)"
        case .custom:
            quantity = nil
        }

        let strikeStyle: NSUnderlineStyle = item.checked ? .single : []
        let attributes = [NSAttributedString.Key.strikethroughStyle: strikeStyle.rawValue]
        let attributedText = NSAttributedString(string: item.name, attributes: attributes)

        cellView?.configure(
            withName: attributedText,
            isItemChecked: item.checked,
            quantity: quantity
        )
        loadImage(for: item)
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
            Task { @MainActor in
                self.task = nil
                self.cellView?.spinner?.stopAnimating()
            }
            guard let data = data, error == nil else {
                return
            }

            Task { @MainActor in
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

    @MainActor private func setDefaultImage(for item: ShoppingListItem) {
        let asset: UIImage?
        switch item.entry {
        case .product:
            asset = Asset.image(named: "SnabbleSDK/shoppinglist/shoppinglist-icon-product")
        case .tag:
            asset = Asset.image(named: "SnabbleSDK/shoppinglist/shoppinglist-icon-tag")
        case .custom:
            asset = Asset.image(named: "SnabbleSDK/shoppinglist/shoppinglist-icon-text")
        }

        self.cellView?.configureProductImage(with: asset?.withRenderingMode(.alwaysTemplate))
    }
}
