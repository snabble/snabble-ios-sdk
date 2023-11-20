//
//  ReceiptsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 20.10.23.
//  Copyright © 2023 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleUI

final class ReceiptsViewController: ReceiptsListViewController {
    override init() {
        super.init()
        
        self.title = NSLocalizedString("receipts", comment: "")
        self.tabBarItem.image = UIImage(systemName: "scroll")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
