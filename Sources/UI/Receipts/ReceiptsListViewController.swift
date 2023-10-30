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

    public var viewModel: LastPurchasesViewModel {
        rootView.viewModel
    }
    
    public init() {
        let rootView = ReceiptsListScreen(projectId: Snabble.shared.projects.first?.id)

        super.init(rootView: rootView)

        viewModel.actionPublisher
            .sink { [unowned self] provider in
                self.actionFor(provider: provider)
            }
            .store(in: &cancellables)
        
        viewModel.$numberOfUnloaded
            .sink { [unowned self] value in
                self.update(unloaded: value)
            }
            .store(in: &cancellables)
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var usedTabBarItem: UITabBarItem {
        guard self.tabBarItem.title != nil else {
            while let parent = self.parent {
                if parent.tabBarItem.title != nil {
                    return parent.tabBarItem
                }
            }
            return self.tabBarItem
        }
        return self.tabBarItem
    }

    private func update(unloaded: Int) {
        usedTabBarItem.badgeValue = unloaded > 0 ? "\(unloaded)" : nil
        UIApplication.shared.applicationIconBadgeNumber = unloaded
        self.view.setNeedsDisplay()
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

