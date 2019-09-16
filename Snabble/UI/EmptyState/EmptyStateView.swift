//
//  EmptyStateView.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

class EmptyStateView: NibView {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!

    typealias Handler = (UIButton) -> ()
    private let tapHandler: Handler
    
    init(_ tapHandler: @escaping Handler) {
        self.tapHandler = tapHandler
        super.init(frame: CGRect.zero)

        self.backgroundColor = SnabbleUI.appearance.backgroundColor

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

        self.textLabel.text = "Snabble.Shoppingcart.emptyState.description".localized()
        self.button1.setTitle("Snabble.Shoppingcart.emptyState.buttonTitle".localized(), for: .normal)
        self.button1.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)

        self.button2.setTitle("Snabble.Shoppingcart.emptyState.restoreButtonTitle".localized(), for: .normal)
        self.button2.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)
        self.button2.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BarcodeEntryEmptyStateView: EmptyStateView {
    override init(_ tapHandler: @escaping Handler) {
        super.init(tapHandler)

        self.textLabel.text = "Snabble.Scanner.enterBarcode".localized()

        self.button1.setTitle("", for: .normal)
        self.button1.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)

        self.button2.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
