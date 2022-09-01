//
//  DashboardViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 31.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK

final class DashboardViewController: SnabbleSDK.DynamicStackViewController {
    
    override init(viewModel: DynamicStackViewModel) {
        super.init(viewModel: viewModel)
        
        self.title = "Snabble"

        self.tabBarItem.image = UIImage(named: "Navigation/TabBar/home-off")
        self.tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/home-on")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
