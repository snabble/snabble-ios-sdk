//
//  ProductAddViewController.swift
//  
//
//  Created by Uwe Tilemann on 03.11.22.
//

import SnabbleCore
import UIKit
import SwiftUI

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class CartItemAddViewController: UIHostingController<CartItemAddView> {

    /// Creates and returns a view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the item to add to the cart
    public init(viewModel: CartItemModel) {
        super.init(rootView: CartItemAddView(viewModel: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
