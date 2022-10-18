//
//  CheckoutInformationView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 05.10.21.
//

import Foundation
import UIKit

protocol CheckoutInformationViewModel {
    var text: String { get }
    var actionTitle: String? { get }
}

final class CheckoutInformationView: UIView {
    private(set) weak var textLabel: UILabel?
    private(set) weak var button: UIButton?

    private weak var stackView: UIStackView?

    override init(frame: CGRect) {
        let textLabel = UILabel()
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
        textLabel.font = .preferredFont(forTextStyle: .footnote)
        textLabel.adjustsFontForContentSizeCategory = true

        let button = UIButton(type: .system)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote, weight: .medium)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [textLabel, button])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.alignment = .leading

        super.init(frame: frame)

        addSubview(stackView)
        self.stackView = stackView
        self.textLabel = textLabel
        self.button = button

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CheckoutInformationViewModel) {
        textLabel?.text = viewModel.text
        button?.setTitle(viewModel.actionTitle, for: .normal)
        button?.isHidden = viewModel.actionTitle == nil
    }
}

extension CheckoutStep: CheckoutInformationViewModel {}

#if canImport(SwiftUI) && DEBUG
extension CheckoutInformationView {
    struct ViewModel: CheckoutInformationViewModel {
        let text: String
        let actionTitle: String?

        static var mock: Self {
            .init(
                text: "Möchtest du die Daten deiner girocard sicher in der App speichern, um deinen nächsten Einkauf per Lastschrift zu bezahlen? Die Karte kannst du zukünftig im Geldbeutel lassen.",
                actionTitle: "Ja, Daten in der App speichern"
            )
        }
    }
}

import SwiftUI

@available(iOS 13, *)
public struct CheckoutInformationView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            UIViewPreview {
                let view = CheckoutInformationView()
                view.configure(with: CheckoutInformationView.ViewModel.mock)
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutInformationView()
                view.configure(with: CheckoutInformationView.ViewModel.mock)
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
