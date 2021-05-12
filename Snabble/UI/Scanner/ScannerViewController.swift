//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: PulleyViewController {

    private let scanningViewController: ScanningViewController
    private let drawerViewController: ScannerDrawerViewController

    public init(_ cart: ShoppingCart, _ shop: Shop, _ detector: BarcodeDetector, scannerDelegate: ScannerDelegate, cartDelegate: ShoppingCartDelegate) {
        scanningViewController = ScanningViewController(cart, shop, detector, delegate: scannerDelegate)
        drawerViewController = ScannerDrawerViewController(SnabbleUI.project.id, shoppingCart: cart, delegate: cartDelegate)

        super.init(contentViewController: scanningViewController, drawerViewController: drawerViewController)
        self.initialDrawerPosition = .collapsed

        self.title = "Snabble.Scanner.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-scan-active")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
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

}
