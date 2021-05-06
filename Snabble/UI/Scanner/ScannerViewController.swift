//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: PulleyViewController {

    public init(_ cart: ShoppingCart, _ shop: Shop, _ detector: BarcodeDetector, delegate: ScannerDelegate) {
        let scanningVC = ScanningViewController(cart, shop, detector, delegate: delegate)
        let drawerVC = ScannerDrawerViewController(SnabbleUI.project.id, delegate: delegate)

        super.init(contentViewController: scanningVC, drawerViewController: drawerVC)

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
