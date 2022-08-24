//
//  ShopsViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import Foundation
import UIKit
import SwiftUI

/// A UIViewController wrapping SwiftUI's ShopsView
open class ShopsViewController: UIHostingController<ShopsView> {
    var viewModel: ShopsViewModel {
        rootView.viewModel
    }

    public init(shops: [ShopInfoProvider]) {
        let rootView = ShopsView(shops: shops)
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
