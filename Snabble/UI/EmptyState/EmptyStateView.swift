//
//  EmptyStateView.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class EmptyStateView: NibView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    typealias Handler = () -> ()
    private let tapHandler: Handler?
    
    init(_ tapHandler: Handler?) {
        self.tapHandler = tapHandler
        super.init(frame: CGRect.zero)

        self.button.isHidden = tapHandler == nil
        self.backgroundColor = SnabbleUI.appearance.primaryBackgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func buttonTapped(_ sender: UIButton) {
        self.tapHandler?()
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

class ShoppingCartEmptyStateView: EmptyStateView {
    override init(_ tapHandler: Handler?) {
        super.init(tapHandler)

        let primaryColor = SnabbleUI.appearance.primaryColor
        self.image.image = UIImage.fromBundle("icon-cart-big")?.recolored(with: primaryColor)
        self.titleLabel.text = "Snabble.Shoppingcart.emptyState.title".localized()
        self.descriptionLabel.text = "Snabble.Shoppingcart.emptyState.description".localized()
        self.button.setTitle("Snabble.Shoppingcart.emptyState.buttonTitle".localized(), for: .normal)
        self.button.setImage(UIImage.fromBundle("icon-scan")?.recolored(with: primaryColor), for: .normal)
        self.button.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BarcodeEntryEmptyStateView: EmptyStateView {
    override init(_ tapHandler: Handler?) {
        super.init(tapHandler)

        self.image.image = nil
        self.image.isHidden = true
        self.titleLabel.text = "Snabble.Scanner.enterBarcode".localized()
        self.descriptionLabel.text = nil
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        self.button.setTitle("", for: .normal)
        self.button.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
