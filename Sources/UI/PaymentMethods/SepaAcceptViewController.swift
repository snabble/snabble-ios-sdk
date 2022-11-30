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

/// Methods for managing callbacks for widges
public protocol SepaAcceptViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaAcceptViewController(_ viewController: SepaAcceptViewController, userInfo:[String:Any]?)
}


/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaAcceptViewController: UIHostingController<SepaAcceptView> {
    public weak var delegate: SepaAcceptViewControllerDelegate?

    private var completionHandler: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    public var viewModel: SepaAcceptModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaAcceptModel, completion: @escaping () -> Void ) {
        super.init(rootView: SepaAcceptView(model: viewModel))
       
        self.completionHandler = completion
        self.delegate = self
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
        
    func accept(model: SepaAcceptModel) {
        Task {
            do {
                try await model.accept(completion: completionHandler ?? { })

                DispatchQueue.main.async {
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = AlertView(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.authorizingError"))
                    
                    alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
                        self.dismiss()
                    })
                    alert.show()
                }
            }
        }
    }

    public func sepaAcceptViewController(_ viewController: SepaAcceptViewController, userInfo:[String:Any]?) {
        if let action = userInfo?["action"] as? String {
            switch action {
            case "accept":
                self.accept(model: viewController.viewModel)
                
            case "paymentFinished":
                print("paymentFinsihed")

            case "paymentFailed":
                print("paymentFailed")

            case "authorizingFailed":
                print("authorizingFailed")

            default:
                print("unahndled action: \(action)")
                break
            }
        }
    }
    
    @objc
    private func dismiss() {
        self.navigationController?.popViewController(animated: true)
    }
}
