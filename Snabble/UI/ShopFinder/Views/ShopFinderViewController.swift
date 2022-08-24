//
//  ShopFinderViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import Foundation
import UIKit
import SwiftUI

/// A UIViewController wrapping SwiftUI's ShopFinderView
open class ShopFinderViewController: UIHostingController<ShopFinderView> {
    var viewModel: ShopFinderViewModel {
        rootView.viewModel
    }

    public init(shops: [ShopInfoProvider]) {
        let rootView = ShopFinderView(shops: shops)
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
