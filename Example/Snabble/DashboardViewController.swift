//
//  DashboardViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 31.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK

final class DashboardViewController: SnabbleSDK.DynamicViewController {
    
    override init(viewModel: DynamicViewModel) {
        super.init(viewModel: viewModel)

        title = NSLocalizedString("home", comment: "")

        tabBarItem.image = UIImage(named: "Navigation/TabBar/home-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/home-on")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
