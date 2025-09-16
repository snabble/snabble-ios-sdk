//
//  ReceiptsListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SwiftUI
import Combine

public protocol ReceiptsListDelegate: AnyObject {
    func handleAction(_ viewController: ReceiptsListViewController, on receipt: PurchaseProviding) -> Bool
}

/// A UIViewController wrapping SwiftUI's ReceiptsListViewController
open class ReceiptsListViewController: UIHostingController<ReceiptsListScreen> {

    private var cancellables = Set<AnyCancellable>()
    public weak var delegate: ReceiptsListDelegate?
    public weak var analyticsDelegate: AnalyticsDelegate?
    public weak var detailDelegate: ReceiptsDetailViewControllerDelegate?

    public var viewModel: PurchasesViewModel {
        rootView.viewModel
    }

    public init() {
        let rootView = ReceiptsListScreen()
        
        super.init(rootView: rootView)
        
        viewModel.actionPublisher
            .sink { [unowned self] provider in
                self.actionFor(provider: provider)
            }
            .store(in: &cancellables)
        
        viewModel.numberOfUnloadedPublisher
            .sink { [unowned self] value in
                self.update(unloaded: value)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(update(_:)),
            name: .snabbleCartUpdated, object: nil)
        
       NotificationCenter.default.addObserver(
            self,
            selector: #selector(update(_:)),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(unloaded: Int) {
        tabBarItem.badgeValue = unloaded > 0 ? "\(unloaded)" : nil
        self.view.setNeedsDisplay()
    }

    @objc private func update(_ notification: Notification) {
        if notification.name == .snabbleCartUpdated, let cart = notification.object as? ShoppingCart, cart.numberOfItems == 0 {
            self.viewModel.load()
        }
        if notification.name == UIApplication.willEnterForegroundNotification {
            self.viewModel.load()
        }
    }

    private func actionFor(provider: PurchaseProviding) {
        if !self.handleAction(self, on: provider) {
            let detailController = ReceiptsDetailViewController(orderId: provider.id, projectId: provider.projectId)
            detailController.delegate = detailDelegate
            detailController.analyticsDelegate = analyticsDelegate
            self.navigationController?.pushViewController(detailController, animated: true)
        }
    }
}

extension ReceiptsListViewController: ReceiptsListDelegate {
    public func handleAction(_ viewController: ReceiptsListViewController, on receipt: PurchaseProviding) -> Bool {
        return delegate?.handleAction(viewController, on: receipt) ?? false
    }
}
