//
//  PaymentMethodAddCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import ColorCompatibility

protocol PaymentMethodAddCellViewModel {
    var projectId: Identifier<Project> { get }
    var name: String { get }
    var count: String { get }
}

final class PaymentMethodAddCell: UITableViewCell {
    private weak var icon: UIImageView?
    private weak var nameLabel: UILabel?
    private weak var countLabel: UILabel?

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

        countLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        countLabel.textColor = ColorCompatibility.systemGray2

        self.accessoryType = .disclosureIndicator

        let noImageWidthConstraint = icon.widthAnchor.constraint(equalToConstant: 0)
        noImageWidthConstraint.priority = .defaultHigh

        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        countLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 24),
            noImageWidthConstraint,

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            countLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
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

    struct ViewModel: PaymentMethodAddCellViewModel {
        let projectId: Identifier<Project>
        let name: String
        let count: String

        init(methodEntry: MethodEntry) {
            projectId = methodEntry.projectId
            name = methodEntry.name
            count = "\(methodEntry.count)"
        }
    }

    private var projectId: Identifier<Project>?

    func configure(with viewModel: PaymentMethodAddCellViewModel) {
        nameLabel?.text = viewModel.name

        projectId = viewModel.projectId
        SnabbleUI.getAsset(.storeIcon, projectId: viewModel.projectId) { [weak self] img in
            if self?.projectId == viewModel.projectId {
                self?.icon?.image = img
            }
        }
        countLabel?.text = viewModel.count
    }
}
