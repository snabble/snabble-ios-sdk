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

/// Methods for managing callbacks for widges
public protocol SepaDataEditViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaDataEditViewControllerWillSave(_ viewController: SepaDataEditViewController)
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
            .sink { [unowned self] account in
                delegate?.sepaDataEditViewControllerWillSave(self)
            }
            .store(in: &cancellables)
    }
}

extension SepaDataEditViewController: SepaDataEditViewControllerDelegate {
    
    func save(model: SepaDataModel) {
        if model.isValid, let cert = Snabble.shared.certificates.first, let sepaData = PayoneSepaData(cert.data, iban: model.iban, lastName: model.lastname, city: model.city, countryCode: model.countryCode) {
            let detail = PaymentMethodDetail(sepaData)
            PaymentMethodDetails.save(detail)
        } else {
            let alert = AlertView(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.encryptionError"))
            
            alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default))
            alert.show()
        }
    }
    public func sepaDataEditViewControllerWillSave(_ viewController: SepaDataEditViewController) {
        self.save(model: viewController.viewModel)
    }
}
