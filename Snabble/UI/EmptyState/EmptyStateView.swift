//
//  EmptyStateView.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

internal class EmptyStateView: NibView {
    // swiftlint:disable private_outlet
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    // swiftlint:enable private_outlet

    typealias Handler = (UIButton) -> Void
    private let tapHandler: Handler

    init(_ tapHandler: @escaping Handler) {
        self.tapHandler = tapHandler
        super.init(frame: CGRect.zero)

        self.backgroundColor = .systemBackground

        self.button1.tag = 0
        self.button2.tag = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction private func buttonTapped(_ sender: UIButton) {
        self.tapHandler(sender)
    }

    func addTo(_ superview: UIView) {
        superview.addSubview(self)

        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
        self.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: 16).isActive = true
        self.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -16).isActive = true
    }

    override var nibName: String {
        return "EmptyStateView"
    }
}

final class ShoppingCartEmptyStateView: EmptyStateView {
    override init(_ tapHandler: @escaping Handler) {
        super.init(tapHandler)

        self.textLabel.text = L10n.Snabble.Shoppingcart.EmptyState.description
        self.button1.setTitle(L10n.Snabble.Shoppingcart.EmptyState.buttonTitle, for: .normal)
        self.button1.setTitleColor(.label, for: .normal)

        self.button2.setTitle(L10n.Snabble.Shoppingcart.EmptyState.restoreButtonTitle, for: .normal)
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

        self.textLabel.text = L10n.Snabble.Scanner.enterBarcode

        self.button1.setTitle("", for: .normal)
        self.button1.setTitleColor(.label, for: .normal)

        self.button2.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
