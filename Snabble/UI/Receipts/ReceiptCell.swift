//
//  ReceiptCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class ReceiptCell: UITableViewCell {

    @IBOutlet private var storeIcon: UIImageView!
    @IBOutlet private var storeName: UILabel!
    @IBOutlet private var orderDate: UILabel!
    @IBOutlet private var price: UILabel!

    @IBOutlet private var iconWidth: NSLayoutConstraint!
    @IBOutlet private var iconDistance: NSLayoutConstraint!

    private var projectId: Identifier<Project>?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.storeIcon.image = nil
        self.storeName.text = nil
        self.orderDate.text = nil
        self.price.text = nil

        self.iconWidth.constant = 0
        self.iconDistance.constant = 0

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
            self.orderDate.text = "Snabble.Receipts.loading".localized()
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
            self.iconWidth.constant = 24
            self.iconDistance.constant = 16
        }
    }
}
