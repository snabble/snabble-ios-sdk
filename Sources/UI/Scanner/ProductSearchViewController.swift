//
//  ProductSearchViewController.swift
//  
//
//  Created by Uwe Tilemann on 22.10.22.
//

import Foundation
import SnabbleCore
import UIKit
import SwiftUI
import Combine

/// Methods for managing callbacks for widges
public protocol ProductSearchViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func productSearchViewViewController(_ viewController: ProductSearchViewController, tappedProduct product: Product)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class ProductSearchViewController: UIHostingController<ProductSearchView> {
    public weak var delegate: ProductSearchViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: ProductViewModel {
        rootView.viewModel
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: ProductViewModel) {
        super.init(rootView: ProductSearchView(viewModel: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] product in
                delegate?.productSearchViewViewController(self, tappedProduct: product)
            }
            .store(in: &cancellables)
    }
}
