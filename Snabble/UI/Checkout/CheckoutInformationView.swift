//
//  CheckoutInformationView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 05.10.21.
//

import Foundation
import UIKit

public protocol CheckoutInformationViewModel {
    var text: String { get }
    var buttonTitle: String { get }
}

public final class CheckoutInformationView: UIView {
    public private(set) weak var textLabel: UILabel?
    public private(set) weak var button: UIButton?

    override public init(frame: CGRect) {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
        textLabel.font = .systemFont(ofSize: 13)

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)

        super.init(frame: frame)

        addSubview(textLabel)
        addSubview(button)

        self.textLabel = textLabel
        self.button = button

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 16),

            button.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor, constant: 16),

            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            button.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 8),
            bottomAnchor.constraint(greaterThanOrEqualTo: button.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with viewModel: CheckoutInformationViewModel) {
        textLabel?.text = viewModel.text
        button?.setTitle(viewModel.buttonTitle, for: .normal)
    }

    public struct ViewModel: CheckoutInformationViewModel {
        public let text: String
        public let buttonTitle: String
    }
}

extension CheckoutInformationView.ViewModel {
    public static var mock: Self {
        .init(
            text: "Möchtest du die Daten deiner girocard sicher in der App speichern, um deinen nächsten Einkauf per Lastschrift zu bezahlen? Die Karte kannst du zukünftig im Geldbeutel lassen.",
            buttonTitle: "Ja, Daten in der App speichern"
        )
    }
}
#if canImport(SwiftUI) && DEBUG
import SwiftUI
import AutoLayout_Helper

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
