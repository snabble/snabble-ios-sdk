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
@MainActor
public protocol DynamicViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func dynamicStackViewController(_ viewController: DynamicViewController, tappedWidget widget: Widget, userInfo: [String: Any]?)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
@MainActor
open class DynamicViewController: UIHostingController<DynamicView> {
    public weak var delegate: DynamicViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: DynamicViewModel {
        rootView.viewModel
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: DynamicViewModel) {
        super.init(rootView: DynamicView(viewModel: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] action in
                delegate?.dynamicStackViewController(self, tappedWidget: action.widget, userInfo: action.userInfo)
            }
            .store(in: &cancellables)
    }
}
