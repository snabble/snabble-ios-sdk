//
//  ShoppingCartEmptyStateView.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class ShoppingCartEmptyStateView: NibView {
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    typealias HandlerFunc = (UIButton) -> ()
    private let tapHandler: HandlerFunc
    
    init(_ buttonTapped: @escaping HandlerFunc) {
        self.tapHandler = buttonTapped
        super.init(frame: CGRect.zero)

        let primaryColor = SnabbleAppearance.shared.config.primaryColor
        self.mainImage.image = UIImage.fromBundle("icon-cart-big")?.recolored(with: primaryColor)
        self.titleLabel.text = "Snabble.Shoppingcart.emptyState.title".localized()
        self.descriptionLabel.text = "Snabble.Shoppingcart.emptyState.description".localized()
        self.button.setTitle("Snabble.Shoppingcart.emptyState.buttonTitle".localized(), for: .normal)
        self.button.setImage(UIImage.fromBundle("icon-scan")?.recolored(with: primaryColor), for: .normal)
        self.backgroundColor = SnabbleAppearance.shared.config.primaryBackgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        self.tapHandler(sender)
    }
}
