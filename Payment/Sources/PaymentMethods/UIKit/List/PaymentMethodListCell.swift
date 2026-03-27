//
//  PaymentMethodListCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

protocol PaymentMethodListCellViewModel {
    var displayName: String { get }
    var icon: UIImage? { get }
    var accessoryType: UITableViewCell.AccessoryType { get }
    var selectionStyle: UITableViewCell.SelectionStyle { get }
}

final class PaymentMethodListCell: UITableViewCell {
    private var nameLabel = UILabel()
    private var icon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true

        icon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        contentView.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 38),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
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
        selectionStyle = .none
    }

    func configure(with viewModel: PaymentMethodListCellViewModel) {
        nameLabel.text = viewModel.displayName
        icon.image = viewModel.icon
        accessoryType = viewModel.accessoryType
        selectionStyle = viewModel.selectionStyle
    }

    struct ViewModel: PaymentMethodListCellViewModel {
        let displayName: String
        let icon: UIImage?
        let accessoryType: UITableViewCell.AccessoryType
        let selectionStyle: UITableViewCell.SelectionStyle

        init(detail: PaymentMethodDetail) {
            if detail.originType == .contactPersonCredentials, case let PaymentMethodUserData.invoiceByLogin(data) = detail.methodData {
                displayName = detail.displayName + ": " + data.username
            } else {
                displayName = detail.displayName
            }
            icon = detail.icon
            switch detail.originType {
            case .tegutEmployeeID:
                accessoryType = .none
                selectionStyle = .none
            default:
                accessoryType = .disclosureIndicator
                selectionStyle = .default
            }
        }

        init(displayName: String, icon: UIImage?) {
            self.displayName = displayName
            self.icon = icon
            self.accessoryType = .none
            self.selectionStyle = .none
        }
    }
}
