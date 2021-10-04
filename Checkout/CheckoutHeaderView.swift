//
//  CheckoutHeaderView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit
import AutoLayout_Helper

public protocol CheckoutHeaderViewModel {
    var statusViewModel: CheckoutStatusViewModel { get }
    var text: String { get }
}

public final class CheckoutHeaderView: UIView {
    public private(set) weak var statusView: CheckoutStatusView?
    public private(set) weak var textLabel: UILabel?

    override public init(frame: CGRect) {
        let statusView = CheckoutStatusView()
        statusView.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .label
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        super.init(frame: frame)

        addSubview(statusView)
        addSubview(textLabel)

        self.statusView = statusView
        self.textLabel = textLabel

        NSLayoutConstraint.activate([
            statusView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(greaterThanOrEqualTo: statusView.trailingAnchor, constant: 16),
            statusView.centerXAnchor.constraint(equalTo: centerXAnchor),

            statusView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).usingPriority(.defaultLow),
            trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: 16).usingPriority(.defaultLow),

            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),

            statusView.topAnchor.constraint(equalTo: topAnchor),
            textLabel.topAnchor.constraint(greaterThanOrEqualTo: statusView.bottomAnchor, constant: 8),
            textLabel.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 24).usingPriority(.defaultHigh - 1),
            bottomAnchor.constraint(equalTo: textLabel.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with viewModel: CheckoutHeaderViewModel) {
        statusView?.configure(with: viewModel.statusViewModel)
        textLabel?.text = viewModel.text
    }
}

extension CheckoutStatus: CheckoutHeaderViewModel {
    public var text: String {
        switch self {
        case .loading:
            return L10n.Snabble.Payment.waiting
        case .failure:
            return L10n.Snabble.Payment.rejected
        case .success:
            return L10n.Snabble.Payment.success
        }
    }

    public var statusViewModel: CheckoutStatusViewModel {
        self
    }
}
