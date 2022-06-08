//
//  CheckoutHeaderView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit
import AutoLayout_Helper

protocol CheckoutHeaderViewModel {
    var statusViewModel: CheckoutStepStatusViewModel { get }
    var text: String { get }
}

final class CheckoutHeaderView: UIView {
    private(set) weak var statusView: CheckoutStepStatusView?
    private(set) weak var textLabel: UILabel?

    override init(frame: CGRect) {
        let statusView = CheckoutStepStatusView()
        statusView.circleColor = CheckoutStepStatus.aborted.circleColor
        statusView.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .label
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
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

            statusView.heightAnchor.constraint(equalToConstant: 168),

            statusView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).usingPriority(.defaultLow),
            trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: 16).usingPriority(.defaultLow),

            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),

            statusView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textLabel.topAnchor.constraint(greaterThanOrEqualTo: statusView.bottomAnchor, constant: 8),
            textLabel.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 24).usingPriority(.defaultHigh - 1),
            bottomAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CheckoutHeaderViewModel) {
        statusView?.configure(with: viewModel.statusViewModel)
        textLabel?.text = viewModel.text
    }
}

extension CheckoutStepStatus: CheckoutHeaderViewModel {
    var text: String {
        switch self {
        case .loading:
            return L10n.Snabble.Payment.waiting
        case .failure, .aborted:
            return L10n.Snabble.Payment.rejected
        case .success:
            return L10n.Snabble.Payment.success
        }
    }

    var statusViewModel: CheckoutStepStatusViewModel {
        self
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import AutoLayout_Helper

@available(iOS 13, *)
public struct CheckoutHeaderView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            UIViewPreview {
                let view = CheckoutHeaderView(frame: .zero)
                view.configure(with: CheckoutStepStatus.failure)
                return view
            }.previewLayout(.fixed(width: 100, height: 100))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutHeaderView(frame: .zero)
                view.configure(with: CheckoutStepStatus.failure)
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
