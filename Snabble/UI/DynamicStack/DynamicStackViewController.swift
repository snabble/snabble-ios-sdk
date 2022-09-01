//
//  DynamicStackViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 31.08.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// Methods for managing callbacks for widges
public protocol DynamicStackViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func dynamicStackViewController(_ viewController: DynamicStackViewController, performAction id: String)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class DynamicStackViewController: UIHostingController<DynamicStackView> {
    public weak var delegate: DynamicStackViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: DynamicStackViewModel {
        rootView.viewModel
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: DynamicStackViewModel) {
        super.init(rootView: DynamicStackView(viewModel: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [weak self] widget in
                self?.delegate?.dynamicStackViewController(self!, performAction: widget.id)
            }
            .store(in: &cancellables)
    }
}
