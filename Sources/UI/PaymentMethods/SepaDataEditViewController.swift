//
//  SepaDataEditViewController.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// Methods for managing callbacks for widges
public protocol SepaDataEditViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaDataEditViewController(_ viewController: SepaDataEditViewController, willSave account: SepaDataProviding)
}


/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaDataEditViewController: UIHostingController<SepaDataView> {
    public weak var delegate: SepaDataEditViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: SepaDataViewModel {
        rootView.viewModel
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaDataViewModel) {
        super.init(rootView: SepaDataView(viewModel: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] account in
                delegate?.sepaDataEditViewController(self, willSave: account)
            }
            .store(in: &cancellables)
    }
}
