//
//  ShopsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 18.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK

final class ShopsViewController: ShopFinderViewController {
    override init(shops: [Shop]) {
        super.init(shops: shops)

        self.title = NSLocalizedString("Shops", comment: "")
        self.tabBarItem.image = UIImage(systemName: "house")
        self.tabBarItem.selectedImage = UIImage(systemName: "house.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
