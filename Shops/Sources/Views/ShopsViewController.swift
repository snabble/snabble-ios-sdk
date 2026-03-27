//
//  ShopsViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine

public protocol ShopsViewControllerDelegate: AnyObject {
    func shopsViewController(_ viewController: ShopsViewController, didSelectActionOnShop shop: ShopProviding)
}

/// A UIViewController wrapping SwiftUI's ShopsView
open class ShopsViewController: UIHostingController<ShopsView> {
    public weak var delegate: ShopsViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: ShopsViewModel {
        rootView.viewModel
    }

    public init(shops: [ShopProviding]) {
        let rootView = ShopsView(shops: shops)
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [weak self] shop in
                self?.delegate?.shopsViewController(self!, didSelectActionOnShop: shop)
            }
            .store(in: &cancellables)
    }
}
