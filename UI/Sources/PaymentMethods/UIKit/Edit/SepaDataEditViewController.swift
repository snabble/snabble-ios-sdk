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
import SnabbleCore
import SnabbleAssetProviding

/// Methods for managing callbacks for widges
@MainActor
public protocol SepaDataEditViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaDataEditViewControllerWillSave(_ viewController: SepaDataEditViewController, userInfo: [String: Any]?)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaDataEditViewController: UIHostingController<SepaDataView> {
    public weak var delegate: SepaDataEditViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: SepaDataModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaDataModel) {
        super.init(rootView: SepaDataView(model: viewModel))

        delegate = self
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] info in
                delegate?.sepaDataEditViewControllerWillSave(self, userInfo: info)
            }
            .store(in: &cancellables)
    }
}

extension SepaDataEditViewController: SepaDataEditViewControllerDelegate {
    
    func remove(model: SepaDataModel) {
        model.remove()
    }
    
    func save(model: SepaDataModel) {
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

    public func sepaDataEditViewControllerWillSave(_ viewController: SepaDataEditViewController, userInfo: [String: Any]?) {
        if let action = userInfo?["action"] as? String {
            switch action {
            case "save":
                self.save(model: viewController.viewModel)
                
            case "remove":
                self.remove(model: viewController.viewModel)
                
            default:
                print("unhandled action: \(action)")
            }
        }
    }
}
