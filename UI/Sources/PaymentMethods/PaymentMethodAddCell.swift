//
//  PaymentMethodAddCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

protocol PaymentMethodAddCellViewModel: Sendable {
    var projectId: Identifier<Project> { get }
    var name: String { get }
    var count: String { get }
}

final class PaymentMethodAddCell: UITableViewCell {
    private weak var icon: UIImageView?
    private weak var nameLabel: UILabel?
    private weak var countLabel: UILabel?
    private var projectId: Identifier<Project>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let icon = UIImageView()
        let nameLabel = UILabel()
        let countLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        icon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(icon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)

        self.icon = icon
        self.nameLabel = nameLabel
        self.countLabel = countLabel

        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0

        countLabel.font = .preferredFont(forTextStyle: .subheadline)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.textColor = .systemGray2
        countLabel.textAlignment = .center

        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        countLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        self.accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 24),
            icon.widthAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            countLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        icon?.image = nil
        nameLabel?.text = nil
        countLabel?.text = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: PaymentMethodAddCellViewModel) {
        nameLabel?.text = viewModel.name

        projectId = viewModel.projectId
        SnabbleCI.getAsset(.storeIcon, projectId: viewModel.projectId) { [weak self] img in
            Task { @MainActor in
                if self?.projectId == viewModel.projectId {
                    self?.icon?.image = img
                }
            }
        }
        countLabel?.text = viewModel.count
    }

    struct ViewModel: PaymentMethodAddCellViewModel {
        let projectId: Identifier<Project>
        let name: String
        let count: String
    }
}
