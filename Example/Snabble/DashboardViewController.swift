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
import SwiftUI

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

extension DashboardViewController: ProductSearchViewControllerDelegate {
    func productSearchViewViewController(_ viewController: SnabbleUI.ProductSearchViewController, tappedProduct product: SnabbleCore.Product) {

        let model = CartItemModel(productModel: viewController.viewModel, product: product)
        let itemAddVC = CartItemAddViewController(viewModel: model)
        
        viewController.dismiss(animated: true) {
            self.present(itemAddVC, animated: true)
        }
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
            if let project = Snabble.shared.projects.first,
               let shop = project.shops.first,
               let viewModel = Snabble.shared.productModel(for: project, shop: shop) {

                let productVC = ProductSearchViewController(viewModel: viewModel)
                productVC.delegate = self
                
                self.present(productVC, animated: true)
            }
            
        default:
            break
        }
    }
}
