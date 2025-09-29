//
//  SepaAcceptViewController.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import Combine
import UIKit
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

/// Methods for managing callbacks for widges
@MainActor
public protocol SepaAcceptViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaAcceptViewController(_ viewController: SepaAcceptViewController, userInfo: [String: Any]?)
}

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaAcceptViewController: UIHostingController<SepaAcceptView> {
    public weak var delegate: SepaAcceptViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: SepaAcceptModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaAcceptModel) {
        super.init(rootView: SepaAcceptView(model: viewModel))
       
        self.delegate = self
        modalPresentationStyle = .overFullScreen
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.actionPublisher
            .sink { [unowned self] info in
                delegate?.sepaAcceptViewController(self, userInfo: info)
            }
            .store(in: &cancellables)
    }
}

extension SepaAcceptViewController: SepaAcceptViewControllerDelegate {
        
    func showErrorMessage(title: String?, message: String?) {
        DispatchQueue.main.async {
            let alert = AlertView(title: title, message: message)
            
            alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
                self.dismiss()
            })
            alert.show()
        }
    }

    func perform(action: String) {
        guard action == "accept" || action == "decline" else {
            return
        }
        
        Task {
            do {
                switch action {
                case "accept":
                    try await self.viewModel.accept()
                case "decline":
                    try await self.viewModel.decline()
                default:
                    break
                }

                DispatchQueue.main.async {
                    self.dismiss()
                }
            } catch {
                showErrorMessage(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.authorizingError"))
            }
        }

    }

    public func sepaAcceptViewController(_ viewController: SepaAcceptViewController, userInfo: [String: Any]?) {
        guard viewController == self else {
            return
        }
        
        if let action = userInfo?["action"] as? String {
            switch action {
            case "accept", "decline":
                self.perform(action: action)
                
            case "authorizingFailed":
                showErrorMessage(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.authorizingError"))

            case "cancelPaymentFailed":
                showErrorMessage(title: Asset.localizedString(forKey: "Snabble.Payment.CancelError.title"),
                                 message: Asset.localizedString(forKey: "Snabble.Payment.CancelError.message"))
                
            default:
                print("unhandled action: \(action)")
            }
        }
    }
    
    @objc
    private func dismiss() {
        if let viewController = presentingViewController {
            viewController.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
