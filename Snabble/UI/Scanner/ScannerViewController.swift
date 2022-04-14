//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: PulleyViewController {
    private var customAppearance: CustomAppearance?

    public weak var scannerDelegate: ScannerDelegate? {
        didSet {
            guard let scanningViewController = primaryContentViewController as? ScanningViewController else {
                return
            }
            scanningViewController.scannerDelegate = scannerDelegate
        }
    }

    public weak var shoppingCartDelegate: ShoppingCartDelegate? {
        didSet {
            if let drawerViewController = drawerContentViewController as? ScannerDrawerViewController,
               let shoppingCartDelegate = shoppingCartDelegate {
                drawerViewController.shoppingCartDelegate = shoppingCartDelegate
                drawerViewController.shoppingListDelegate = shoppingListDelegate
                initialDrawerPosition = .collapsed
            } else {
                initialDrawerPosition = .closed
            }
            setDrawerPosition(position: initialDrawerPosition, animated: false, completion: nil)
        }
    }

    public weak var paymentDelegate: PaymentDelegate?

    public weak var shoppingListDelegate: ShoppingListDelegate? {
        didSet {
            guard let scannerDrawerViewController = drawerContentViewController as? ScannerDrawerViewController else {
                return
            }
            scannerDrawerViewController.shoppingListDelegate = shoppingListDelegate
        }
    }

    public let shoppingCart: ShoppingCart
    public let shop: Shop
    public let barcodeDetector: BarcodeDetector

    public init(_ cart: ShoppingCart,
                _ shop: Shop,
                _ detector: BarcodeDetector
    ) {
        self.shoppingCart = cart
        self.shop = shop
        self.barcodeDetector = detector

        let contentViewController = ScanningViewController(cart, shop, detector)
        let drawerViewController = ScannerDrawerViewController(shop.projectId, shoppingCart: shoppingCart)

        super.init(contentViewController: contentViewController, drawerViewController: drawerViewController)
        initialDrawerPosition = .closed

        self.title = L10n.Snabble.Shopping.title
        self.tabBarItem.image = Asset.SnabbleSDK.iconScanInactive.image
        self.tabBarItem.selectedImage = Asset.SnabbleSDK.iconScanActive.image

        SnabbleUI.registerForAppearanceChange(self)

        shoppingCart.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
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

extension ScannerViewController: InternalShoppingCartDelegate {
    func shoppingCart(_ shoppingCart: ShoppingCart, didChangeCustomerCard customerCard: String?) {
        guard let drawer = self.drawerContentViewController as? ScannerDrawerViewController else { return }
        drawer.updateTotals()
    }
}
