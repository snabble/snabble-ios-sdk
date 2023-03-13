//
//  ShoppingCartViewController.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import SnabbleCore

public protocol ShoppingCartViewControllerDelegate: AnyObject {
    func shoppingCartViewController(_ viewController: ShoppingCartViewController, didSelectActionOnShop shop: ShopProviding)
}

/// A UIViewController wrapping SwiftUI's ShopsView
open class ShoppingCartViewController: UIHostingController<ShoppingCartView> {
    public weak var shoppingCartDelegate: ShoppingCartDelegate? {
        didSet {
            self.viewModel.shoppingCartDelegate = shoppingCartDelegate
        }
    }

//    private var cancellables = Set<AnyCancellable>()

    public var viewModel: ShoppingCartViewModel {
        rootView.cartModel
    }

    public init(shoppingCart: ShoppingCart) {
        let rootView = ShoppingCartView(shoppingCart: shoppingCart)
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
//        viewModel.actionPublisher
//            .sink { [weak self] shop in
//                self?.delegate?.shopsViewController(self!, didSelectActionOnShop: shop)
//            }
//            .store(in: &cancellables)
    }
}
