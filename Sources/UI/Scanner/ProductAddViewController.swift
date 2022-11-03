//
//  ProductAddViewController.swift
//  
//
//  Created by Uwe Tilemann on 03.11.22.
//

import SnabbleCore
import UIKit
import SwiftUI
import Combine

/// Methods for managing callbacks for widges
public protocol ProductAddViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func productAddViewViewController(_ viewController: ProductAddViewController, tappedProduct product: Product)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class ProductAddViewController: UIHostingController<ProductAddView> {
    public weak var delegate: ProductAddViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: ProductModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: ProductModel, product: Product) {
        super.init(rootView: ProductAddView(viewModel: viewModel, product: product))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.productActionPublisher
            .sink { [unowned self] product in
                delegate?.productAddViewViewController(self, tappedProduct: product)
            }
            .store(in: &cancellables)
    }
}
