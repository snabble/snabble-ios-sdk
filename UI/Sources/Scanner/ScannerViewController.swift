//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley
import SnabbleCore
import SnabbleAssetProviding

public final class ScannerViewController: PulleyViewController {

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

        let contentViewController = ScanningViewController(forCart: cart, forShop: shop, withDetector: detector)
        let drawerViewController = ScannerDrawerViewController(shop.projectId, shoppingCart: shoppingCart)

        super.init(contentViewController: contentViewController, drawerViewController: drawerViewController)
        initialDrawerPosition = .closed

        self.title = Asset.localizedString(forKey: "Snabble.Shopping.title")
        self.tabBarItem.image = Asset.image(named: "SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = Asset.image(named: "SnabbleSDK/icon-scan-active")

        shoppingCart.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
    }
}

extension ScannerViewController: InternalShoppingCartDelegate {
    public func shoppingCart(_ shoppingCart: ShoppingCart, didChangeCustomerCard customerCard: String?) {
        guard let drawer = self.drawerContentViewController as? ScannerDrawerViewController else { return }
        drawer.updateTotals()
    }

    public func shoppingCart(_ shoppingCart: ShoppingCart, violationsDetected violations: [CheckoutInfo.Violation]) {
        let alertController = UIAlertController(
            title: Asset.localizedString(forKey: "Snabble.Violations.title"),
            message: violations.message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: Asset.localizedString(forKey: "Snabble.ok"),
            style: .default) { _ in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
