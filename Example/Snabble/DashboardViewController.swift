//
//  DashboardViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 31.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleCore
import SnabbleUI
import CoreLocation
import UIKit

final class DashboardViewController: DynamicViewController {
    
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

extension DashboardViewController: DynamicViewControllerDelegate {

    func dynamicStackViewController(_ viewController: DynamicViewController, tappedWidget widget: SnabbleUI.Widget, userInfo: [String: Any]?) {
        print(widget, userInfo?.description ?? "no userInfo")
        switch widget.type {
        case .startShopping:
            tabBarController?.selectedIndex = 1
        case .allStores:
            tabBarController?.selectedIndex = 2
        case .lastPurchases:
            if let action = userInfo?["action"] as? String, action == "more" {
                let viewController = ReceiptsListViewController(checkoutProcess: nil)
                viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))
                let navigationController = UINavigationController(rootViewController: viewController)
                present(navigationController, animated: true)
            }
        default:
            break
        }
    }

    @objc
    private func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
