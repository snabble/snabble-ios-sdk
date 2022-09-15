//
//  DashboardViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 31.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK
import CoreLocation

final class DashboardViewController: SnabbleSDK.DynamicViewController {
    
    override init(viewModel: DynamicViewModel) {
        super.init(viewModel: viewModel)
        delegate = self

        title = NSLocalizedString("home", comment: "")

        tabBarItem.image = UIImage(named: "Navigation/TabBar/home-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/home-on")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DashboardViewController: SnabbleSDK.DynamicViewControllerDelegate {
    func dynamicStackViewController(_ viewController: DynamicViewController, tappedWidget widget: Widget, userInfo: [String: Any]?) {
        print(widget)
        switch widget.type {
        case .startShopping:
            tabBarController?.selectedIndex = 1
        case .allStores:
            tabBarController?.selectedIndex = 2
        default:
            break
        }
    }
}
