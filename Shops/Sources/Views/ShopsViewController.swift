//
//  ShopsViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import Foundation
import UIKit
import SwiftUI

public protocol ShopsViewControllerDelegate: AnyObject {
    func shopsViewController(_ viewController: ShopsViewController, didSelectActionOnShop shop: ShopProviding)
}

/// A UIViewController wrapping SwiftUI's ShopsView
open class ShopsViewController: UIHostingController<ShopsView> {
    public weak var delegate: ShopsViewControllerDelegate?

    nonisolated(unsafe) private var actionTask: Task<Void, Never>?

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
        let publisher = viewModel.actionPublisher
        actionTask = Task { @MainActor [weak self] in
            for await shop in publisher.values {
                guard let self else { return }
                delegate?.shopsViewController(self, didSelectActionOnShop: shop)
            }
        }
    }

    deinit {
        actionTask?.cancel()
    }
}
