//
//  ShopsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 18.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleUI
import UIKit

final class AppShopsViewController: ShopsViewController {
    override init(shops: [ShopProviding]) {
        super.init(shops: shops)

        self.title = NSLocalizedString("shops", comment: "")
        self.tabBarItem.image = UIImage(systemName: "map")
        
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AppShopsViewController: ShopsViewControllerDelegate {
    func shopsViewController(_ viewController: ShopsViewController, didSelectActionOnShop shop: ShopProviding) {
        print(#function, shop)
        tabBarController?.selectedIndex = 1
    }
}
