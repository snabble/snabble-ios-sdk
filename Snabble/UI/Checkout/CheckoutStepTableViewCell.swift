//
//  CheckoutStepTableViewCell.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit

final class CheckoutStepTableViewCell: UITableViewCell, ReuseIdentifiable {
    private(set) weak var stepView: CheckoutStepView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let stepView = CheckoutStepView()
        stepView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(stepView)

        self.stepView = stepView

        NSLayoutConstraint.activate([
            stepView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: stepView.trailingAnchor),
            stepView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: stepView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stepView?.prepareForReuse()
    }
}
