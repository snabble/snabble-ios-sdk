//
//  PaymentMethodListCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

protocol PaymentMethodListCellViewModel {
    var displayName: String { get }
    var icon: UIImage? { get }
    var accessoryType: UITableViewCell.AccessoryType { get }
}

final class PaymentMethodListCell: UITableViewCell {
    private var nameLabel = UILabel()
    private var icon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        contentView.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 38),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        icon.image = nil
        accessoryType = .none
    }

    func configure(with viewModel: PaymentMethodListCellViewModel) {
        nameLabel.text = viewModel.displayName
        icon.image = viewModel.icon
        accessoryType = viewModel.accessoryType
    }

    struct ViewModel: PaymentMethodListCellViewModel {
        let displayName: String
        let icon: UIImage?
        let accessoryType: UITableViewCell.AccessoryType

        init(detail: PaymentMethodDetail) {
            displayName = detail.displayName
            icon = detail.icon
            accessoryType = detail.originType == .tegutEmployeeID ? .none : .disclosureIndicator
        }

        init(displayName: String, icon: UIImage?) {
            self.displayName = displayName
            self.icon = icon
            self.accessoryType = .none
        }
    }
}
