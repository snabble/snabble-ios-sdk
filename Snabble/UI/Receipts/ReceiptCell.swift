//
//  ReceiptCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import AutoLayout_Helper

final class ReceiptCell: UITableViewCell {
    private let storeIcon = UIImageView()
    private let storeName = UILabel()
    private let orderDate = UILabel()
    private let price = UILabel()

    private var iconWidth: NSLayoutConstraint?
    private var iconDistance: NSLayoutConstraint?

    private var projectId: Identifier<Project>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        storeIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(storeIcon)

        storeName.translatesAutoresizingMaskIntoConstraints = false
        storeName.numberOfLines = 0
        storeName.useDynamicFont(forTextStyle: .body)
        contentView.addSubview(storeName)

        orderDate.translatesAutoresizingMaskIntoConstraints = false
        orderDate.numberOfLines = 0
        orderDate.textColor = .secondaryLabel
        orderDate.useDynamicFont(forTextStyle: .footnote)
        contentView.addSubview(orderDate)

        price.translatesAutoresizingMaskIntoConstraints = false
        price.textColor = .secondaryLabel
        price.useDynamicFont(forTextStyle: .footnote)
        price.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        price.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(price)

        NSLayoutConstraint.activate([
            storeIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            storeIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            storeIcon.heightAnchor.constraint(equalTo: storeIcon.widthAnchor),
            storeIcon.widthAnchor.constraint(equalToConstant: 0)
                .usingVariable(&iconWidth),

            storeName.leadingAnchor.constraint(equalTo: storeIcon.trailingAnchor, constant: 0)
                .usingVariable(&iconDistance),
            storeName.trailingAnchor.constraint(equalTo: price.leadingAnchor, constant: -16),
            storeName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            orderDate.leadingAnchor.constraint(equalTo: storeName.leadingAnchor),
            orderDate.trailingAnchor.constraint(equalTo: price.leadingAnchor, constant: -16),
            orderDate.topAnchor.constraint(equalTo: storeName.bottomAnchor, constant: 8),
            orderDate.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            price.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            price.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.storeIcon.image = nil
        self.storeName.text = nil
        self.orderDate.text = nil
        self.price.text = nil

        self.iconWidth?.constant = 0
        self.iconDistance?.constant = 0

        self.projectId = nil
    }

    func show(_ orderEntry: OrderEntry) {
        switch orderEntry {
        case .done(let order):
            if let project = SnabbleAPI.project(for: order.projectId) {
                let formatter = PriceFormatter(project)
                self.price.text = formatter.format(order.price)
            } else {
                let formatter = PriceFormatter(2, "de_DE", "EUR", "€")
                self.price.text = formatter.format(order.price)
            }

            self.storeName.text = order.shopName

            self.showIcon(order.projectId)

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: order.date)
            self.orderDate.text = date

        case .pending(let shopName, let projectId):
            self.storeName.text = shopName
            self.showIcon(projectId)
            self.orderDate.text = L10n.Snabble.Receipts.loading
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            self.accessoryView = spinner
            self.price.text = ""
        }
    }

    private func showIcon(_ projectId: Identifier<Project>) {
        self.projectId = projectId

        SnabbleUI.getAsset(.storeIcon, projectId: projectId) { [weak self] img in
            if let img = img, self?.projectId == projectId {
                self?.updateImage(img)
            } else {
                self?.updateImage(UIImage(named: projectId.rawValue))
            }
        }
    }

    private func updateImage(_ img: UIImage?) {
        self.storeIcon.image = img
        if img != nil {
            self.iconWidth?.constant = 24
            self.iconDistance?.constant = 16
        }
    }
}
