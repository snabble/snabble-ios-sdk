//
//  ShopperNavigation.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 04.07.24.
//

import SwiftUI
import SnabbleComponents

extension Shopper {
    @ViewBuilder
    public func navigationDestinationView() -> some View {
        if let item = navigationItem {
            ContainerView(viewController: item.viewController)
                .navigationTitle(item.viewController.navigationItem.title ?? "")
        }
    }
}
