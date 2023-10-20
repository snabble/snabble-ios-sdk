//
//  ReceiptsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 20.10.23.
//  Copyright © 2023 snabble. All rights reserved.
//

import UIKit
import SnabbleUI

final class ReceiptsViewController: ReceiptsListViewController {
    override init() {
        super.init()
        
        self.title = NSLocalizedString("Receipts.title", comment: "")
        self.tabBarItem.image = UIImage(systemName: "scroll")
        self.tabBarItem.selectedImage = UIImage(systemName: "scroll.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
