//
//  EmptyStateView.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleAssetProviding

internal class EmptyStateView: UIView {
    let textLabel = UILabel()
    let button1 = MultilineButton()
    let button2 = MultilineButton()

    typealias Handler = (UIButton) -> Void
    private let tapHandler: Handler

    init(_ tapHandler: @escaping Handler) {
        self.tapHandler = tapHandler
        super.init(frame: CGRect.zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground

        button1.tag = 0
        button1.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button1.titleLabel?.adjustsFontForContentSizeCategory = true
        button1.addTarget(self, action: #selector(self.buttonTapped(_:)), for: .touchUpInside)

        button2.tag = 1
        button2.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button2.titleLabel?.adjustsFontForContentSizeCategory = true
        button2.addTarget(self, action: #selector(self.buttonTapped(_:)), for: .touchUpInside)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.font = .preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        addSubview(textLabel)

        let stackView = UIStackView(arrangedSubviews: [ button1, button2 ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -16),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        self.tapHandler(sender)
    }

    func addTo(_ superview: UIView) {
        superview.addSubview(self)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16),
            topAnchor.constraint(greaterThanOrEqualTo: superview.topAnchor, constant: 16),
            bottomAnchor.constraint(lessThanOrEqualTo: superview.bottomAnchor, constant: -16),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            centerXAnchor.constraint(equalTo: superview.centerXAnchor)
        ])
    }
}

final class ShoppingCartEmptyStateView: EmptyStateView {
    override init(_ tapHandler: @escaping Handler) {
        super.init(tapHandler)

        self.textLabel.text = Asset.localizedString(forKey: "Snabble.Shoppingcart.EmptyState.description")
        self.button1.setTitle(Asset.localizedString(forKey: "Snabble.Shoppingcart.EmptyState.buttonTitle"), for: .normal)
        self.button1.setTitleColor(.label, for: .normal)

        self.button2.setTitle(Asset.localizedString(forKey: "Snabble.Shoppingcart.EmptyState.restoreButtonTitle"), for: .normal)
        self.button2.setTitleColor(.label, for: .normal)
        self.button2.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BarcodeEntryEmptyStateView: EmptyStateView {
    override init(_ tapHandler: @escaping Handler) {
        super.init(tapHandler)

        self.textLabel.text = Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode")

        self.button1.setTitle("", for: .normal)
        self.button1.setTitleColor(.label, for: .normal)

        self.button2.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
