//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: PulleyViewController {
    private let initialPosition: PulleyPosition
    private var customAppearance: CustomAppearance?

    public init(_ cart: ShoppingCart,
                _ shop: Shop,
                _ detector: BarcodeDetector,
                scannerDelegate: ScannerDelegate,
                cartDelegate: ShoppingCartDelegate?,
                shoppingListDelegate: ShoppingListDelegate?
    ) {
        let scanningViewController = ScanningViewController(cart, shop, detector, delegate: scannerDelegate)

        var viewController: UIViewController
        if let cartDelegate = cartDelegate, let project = shop.project {
            viewController = ScannerDrawerViewController(
                project.id,
                shoppingCart: cart,
                cartDelegate: cartDelegate,
                shoppingListDelegate: shoppingListDelegate
            )
            initialPosition = .collapsed
        } else {
            viewController = EmptyDrawerViewController()
            initialPosition = .closed
        }

        super.init(contentViewController: scanningViewController, drawerViewController: viewController)
        self.initialDrawerPosition = initialPosition

        self.title = L10n.Snabble.Shopping.title
        self.tabBarItem.image = Asset.SnabbleSDK.iconScanInactive.image
        self.tabBarItem.selectedImage = Asset.SnabbleSDK.iconScanActive.image

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
    }

    public func updateTotals() {
        let cartController = self.drawerContentViewController as? ShoppingCartViewController
        cartController?.updateTotals()
    }
}

extension ScannerViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance

        if let drawer = self.drawerContentViewController as? ScannerDrawerViewController {
            drawer.setCustomAppearance(appearance)
        }
    }
}

// MARK: - empty drawer

private final class EmptyDrawerViewController: UIViewController { }

extension EmptyDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed]
    }
}
