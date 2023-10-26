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

        tabBarItem.image = UIImage(systemName: "house")
        self.view.backgroundColor = UIColor(named: "DashboardBackground")
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
            func presentController(_ previewController: UIViewController) {
                previewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))
                let navigationController = UINavigationController(rootViewController: previewController)
                present(navigationController, animated: true)
            }
            if let action = userInfo?["action"] as? String, action == "more" {
                presentController(ReceiptsListViewController())
            } else if let action = userInfo?["action"] as? String, action == "purchase",
                      let orderID = userInfo?["id"] as? String, let projectID = (widget as? WidgetLastPurchases)?.projectId {
                presentController(ReceiptsDetailViewController(orderId: orderID, projectId: projectID))
            }
        default:
            break
        }
    }

    @objc
    private func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
}
