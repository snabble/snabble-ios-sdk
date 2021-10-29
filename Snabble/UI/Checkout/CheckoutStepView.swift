//
//  CheckoutStepView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 05.10.21.
//

import Foundation
import UIKit

protocol CheckoutStepViewModel {
    var statusViewModel: CheckoutStepStatusViewModel { get }
    var text: String { get }
    var detailText: String? { get }
    var actionTitle: String? { get }
    var image: UIImage? { get }
}

final class CheckoutStepView: UIView {
    public private(set) weak var statusView: CheckoutStepStatusView?
    public private(set) weak var textLabel: UILabel?
    public private(set) weak var detailTextLabel: UILabel?
    public private(set) weak var button: UIButton?
    public private(set) weak var imageView: UIImageView?

    private weak var stackView: UIStackView?

    override public init(frame: CGRect) {
        let statusView = CheckoutStepStatusView()
        statusView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 8

        let textLabel = UILabel()
        textLabel.textColor = .label
        textLabel.font = .systemFont(ofSize: 17)
        textLabel.numberOfLines = 1
        textLabel.minimumScaleFactor = 13.0 / 17.0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.allowsDefaultTighteningForTruncation = true

        let detailTextLabel = UILabel()
        detailTextLabel.textColor = .label
        detailTextLabel.font = .systemFont(ofSize: 13)
        detailTextLabel.numberOfLines = 0

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit

        let button = UIButton(type: .system)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.titleLabel?.textAlignment = .left

        super.init(frame: frame)

        addSubview(statusView)
        addSubview(stackView)

        self.statusView = statusView
        self.stackView = stackView

        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(detailTextLabel)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(button)

        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.imageView = imageView
        self.button = button

        NSLayoutConstraint.activate([
            statusView.heightAnchor.constraint(equalToConstant: 24),
            statusView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),

            statusView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: statusView.bottomAnchor, constant: 16),

            stackView.topAnchor.constraint(equalTo: statusView.topAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CheckoutStepViewModel) {
        statusView?.configure(with: viewModel.statusViewModel)
        textLabel?.text = viewModel.text

        detailTextLabel?.text = viewModel.detailText
        button?.setTitle(viewModel.actionTitle, for: .normal)
        imageView?.image = viewModel.image

        detailTextLabel?.isHidden = detailTextLabel?.text == nil
        button?.isHidden = button?.title(for: .normal) == nil
        imageView?.isHidden = imageView?.image == nil
    }
}

extension CheckoutStep: CheckoutStepViewModel {
    var statusViewModel: CheckoutStepStatusViewModel {
        status ?? .loading
    }
}
