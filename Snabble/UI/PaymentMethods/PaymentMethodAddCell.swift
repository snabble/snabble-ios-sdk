//
//  PaymentMethodAddCell.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import ColorCompatibility

struct MethodEntry {
    var name: String
    let brandId: Identifier<Brand>?
    let projectId: Identifier<Project>?
    var count: Int

    init(project: Project, count: Int) {
        self.init(projectId: project.id, name: project.name, brandId: project.brandId, count: count)
    }

    init(projectId: Identifier<Project>, name: String, brandId: Identifier<Brand>?, count: Int) {
        self.projectId = projectId
        self.name = name
        self.brandId = brandId
        self.count = count
    }
}

final class PaymentMethodAddCell: UITableViewCell {
    private var icon: UIImageView
    private var nameLabel: UILabel
    private var countLabel: UILabel

    var entry: MethodEntry? {
        didSet {
            nameLabel.text = entry?.name

            if let projectId = entry?.projectId {
                SnabbleUI.getAsset(.storeIcon, projectId: projectId) { img in
                    self.icon.image = img
                }
            }
            if let count = entry?.count {
                countLabel.text = "\(count)"
            } else {
                countLabel.text = nil
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        icon = UIImageView()
        nameLabel = UILabel()
        countLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        icon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(icon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)

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

        icon.image = nil
        nameLabel.text = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
