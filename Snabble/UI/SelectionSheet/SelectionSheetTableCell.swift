//
//  SelectionSheetTableCell.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class SelectionSheetTableCell: UITableViewCell {
    private let image = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.alignment = .center
        hStack.spacing = 8
        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            hStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 57)
        ])

        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        vStack.axis = .vertical
        vStack.spacing = 8

        hStack.addArrangedSubview(image)
        hStack.addArrangedSubview(vStack)

        titleLabel.numberOfLines = 0

        subtitleLabel.numberOfLines = 0

        image.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with action: SelectionSheetAction, appearance: SelectionSheetAppearance) {
        titleLabel.text = action.title
        titleLabel.textAlignment = action.image == nil ? .center : .left
        titleLabel.font = appearance.actionTitleFont
        titleLabel.textColor = appearance.actionTitleColor

        subtitleLabel.text = action.subTitle
        subtitleLabel.textAlignment = action.image == nil ? .center : .left
        subtitleLabel.isHidden = action.subTitle == nil
        subtitleLabel.font = appearance.actionSubtitleFont
        subtitleLabel.textColor = appearance.actionSubtitleColor

        image.image = action.image
        image.isHidden = action.image == nil

        contentView.backgroundColor = appearance.backgroundColor
    }
}
