//
//  ShopsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 18.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleUI

final class ShopsViewController: SnabbleUI.ShopsViewController {
    override init(shops: [ShopProviding]) {
        super.init(shops: shops)

        self.title = NSLocalizedString("shops", comment: "")
        self.tabBarItem.image = UIImage(named: "Navigation/TabBar/shops-off")
        self.tabBarItem.selectedImage = UIImage(systemName: "Navigation/TabBar/shops-on")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
