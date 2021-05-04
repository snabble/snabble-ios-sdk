//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

public final class ScannerViewController: UIViewController {

    public init(_ cart: ShoppingCart, _ shop: Shop, _ detector: BarcodeDetector? = nil, delegate: ScannerDelegate) {
        super.init(nibName: nil, bundle: nil)

        self.title = "Snabble.Scanner.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-scan-active")

        let scanningVC = ScanningViewController(cart, shop, detector, delegate: delegate)
        let drawerVC = ScannerDrawerViewController(SnabbleUI.project.id, delegate: delegate)

        let pulleyVC = PulleyViewController(contentViewController: scanningVC, drawerViewController: drawerVC)

        view.addSubview(pulleyVC.view)
        addChild(pulleyVC)
        pulleyVC.didMove(toParent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
