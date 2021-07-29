//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: PulleyViewController {
    private let scanningViewController: ScanningViewController
    private let drawerViewController: UIViewController
    private let initialPosition: PulleyPosition
    private var customAppearance: CustomAppearance?

    public init(_ cart: ShoppingCart,
                _ shop: Shop,
                _ detector: BarcodeDetector,
                scannerDelegate: ScannerDelegate,
                cartDelegate: ShoppingCartDelegate?,
                shoppingListDelegate: ShoppingListDelegate?
    ) {
        scanningViewController = ScanningViewController(cart, shop, detector, delegate: scannerDelegate)

        if let cartDelegate = cartDelegate {
            drawerViewController = ScannerDrawerViewController(SnabbleUI.project.id,
                                                               shoppingCart: cart,
                                                               cartDelegate: cartDelegate,
                                                               shoppingListDelegate: shoppingListDelegate)
            initialPosition = .collapsed
        } else {
            drawerViewController = EmptyDrawerViewController()
            initialPosition = .closed
        }

        super.init(contentViewController: scanningViewController, drawerViewController: drawerViewController)
        self.initialDrawerPosition = initialPosition

        self.title = L10n.Snabble.Scanner.title
        self.tabBarItem.image = UIImage.fromBundle("SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-scan-active")

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
    }

    public func updateTotals() {
        let cartController = self.drawerViewController as? ShoppingCartViewController
        cartController?.updateTotals()
    }
}

extension ScannerViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance

        self.scanningViewController.setCustomAppearance(appearance)
        if let drawer = self.drawerViewController as? ScannerDrawerViewController {
            drawer.setCustomAppearance(appearance)
        }
    }
}

// stuff that's only used by the RN wrapper
extension ScannerViewController: ReactNativeWrapper {
    public func setIsScanning(_ on: Bool) {
        scanningViewController.setIsScanning(on)
    }

    public func setLookupcode(_ code: String) {
        scanningViewController.setLookupcode(code)
    }

    public func setTorchOn(_ on: Bool) {
        scanningViewController.setTorchOn(on)
    }
}

// MARK: - empty drawer

private final class EmptyDrawerViewController: UIViewController { }

extension EmptyDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed]
    }
}
