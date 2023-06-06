//
//  InvoiceLoginViewController.swift
//  
//
//  Created by Uwe Tilemann on 02.06.23.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import SnabbleCore

/// Methods for managing callbacks
public protocol InvoiceViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func invoiceViewControllerDidEnd(_ viewController: InvoiceViewController, userInfo: [String: Any]?)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class InvoiceViewController: UIHostingController<InvoiceView> {
    public weak var delegate: InvoiceViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: InvoiceLoginProcessor {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: InvoiceLoginProcessor) {
        super.init(rootView: InvoiceView(model: viewModel))

        delegate = self
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.invoiceLoginModel.actionPublisher
            .sink { [unowned self] info in
                delegate?.invoiceViewControllerDidEnd(self, userInfo: info)
            }
            .store(in: &cancellables)
    }
}

extension InvoiceViewController: InvoiceViewControllerDelegate {
    
    func remove(model: InvoiceLoginProcessor) {
        model.remove()
    }
    
    func save(model: InvoiceLoginProcessor) {
        Task {
            do {
                try await model.save()
            } catch {
                DispatchQueue.main.async {
                    let alert = AlertView(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.encryptionError"))
                    
                    alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default))
                    alert.show()
                }
            }
        }
    }

    public func invoiceViewControllerDidEnd(_ viewController: InvoiceViewController, userInfo: [String: Any]?) {
        if let action = userInfo?["action"] as? String {
            switch action {
            case LoginViewModel.Action.login.rawValue:
                viewModel.login()

            case LoginViewModel.Action.save.rawValue:
                self.save(model: viewController.viewModel)
                
            case LoginViewModel.Action.remove.rawValue:
                self.remove(model: viewController.viewModel)
                
            default:
                print("unhandled action: \(action)")
            }
        }
    }
}
