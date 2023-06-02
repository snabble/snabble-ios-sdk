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
public protocol InvoiceLoginViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func invoiceLoginViewControllerDidEnd(_ viewController: InvoiceLoginViewController, userInfo: [String: Any]?)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class InvoiceLoginViewController: UIHostingController<InvoiceLoginView> {
    public weak var delegate: InvoiceLoginViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: InvoiceLoginProcessor {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: InvoiceLoginProcessor) {
        super.init(rootView: InvoiceLoginView(model: viewModel))

        delegate = self
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] info in
                delegate?.invoiceLoginViewControllerDidEnd(self, userInfo: info)
            }
            .store(in: &cancellables)
    }
}

extension InvoiceLoginViewController: InvoiceLoginViewControllerDelegate {
    
    func remove(model: InvoiceLoginModel) {
        model.delete()
    }
    
    func save(model: InvoiceLoginModel) {
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

    public func invoiceLoginViewControllerDidEnd(_ viewController: InvoiceLoginViewController, userInfo: [String: Any]?) {
        if let action = userInfo?["action"] as? String {
            switch action {
            case "save":
                self.save(model: viewController.viewModel.invoiceLoginModel)
                
            case "remove":
                self.remove(model: viewController.viewModel.invoiceLoginModel)
                
            default:
                print("unhandled action: \(action)")
            }
        }
    }
}
