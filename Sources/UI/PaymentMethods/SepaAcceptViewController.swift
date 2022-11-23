//
//  SepaAcceptViewController.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import SnabbleCore

public final class SepaAcceptModel: ObservableObject {
    /// subscribe to this Publisher to  process
    public var actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    
    let process: CheckoutProcess
    
    init(process: CheckoutProcess) {
        self.process = process
    }
    
    public var markup: String? {
        guard let markup = process.paymentPreauthInformation?.markup,
              let body = markup.replacingOccurrences(of: "+", with: " ").removingPercentEncoding else {
            return nil
        }
        
        let head = """
<html>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
            <style type="text/css">
                pre { font-family: -apple-system, sans-serif; font-size: 15px; white-space: pre-wrap; }
                body { padding: 8px 8px }
                * { font-family: -apple-system, sans-serif; font-size: 15px; word-wrap: break-word }
                *, a { color: #000 }
                h1 { font-size: 22px }
                h2 { font-size: 17px }
                h4 { font-weight: normal; color: #3c3c43; opacity: 0.6 }
                @media (prefers-color-scheme: dark) {
                    a, h4, * { color: #fff }
                }
            </style>
        </head>
        <body>
"""
        let trail  = """
</body></html>
"""
        
        return head + body + trail
    }
}

extension SepaAcceptModel {
    public func accept(completion: @escaping (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) async throws {
                
        print("will authorize")
        
//        if self.isValid,
//           let cert = Snabble.shared.certificates.first,
//           let sepaData = PayoneSepaData(cert.data, iban: self.iban, lastName: self.lastname, city: self.city, countryCode: self.countryCode) {
//
//            let detail = PaymentMethodDetail(sepaData)
//            PaymentMethodDetails.save(detail)
//
//            paymentDetail = detail
//
//            DispatchQueue.main.async {
//                self.objectWillChange.send()
//            }
//        } else {
//            throw PaymentMethodError.encryptionError
//        }
    }
}

public struct SepaAcceptView: View {
    @ObservedObject public var model: SepaAcceptModel

    public init(model: SepaAcceptModel) {
        self.model = model
    }
    
    @ViewBuilder
    var text: some View {
        if let markup = model.markup {
            HTMLView(string: markup)
        } else {
            Text(keyed: "Snabble.SEPA.mandate")
        }
    }
    
    @ViewBuilder
    var button: some View {
        Button(action: {
            model.actionPublisher.send(["action": "accept"])
        }) {
            Text(keyed: "Snabble.SEPA.iAgree")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
    }
    
    public var body: some View {
        VStack {
            text
            button
        }
        .padding()
    }
    
}
/// Methods for managing callbacks for widges
public protocol SepaAcceptViewControllerDelegate: AnyObject {

    /// Tells the delegate that an widget will perform an action
    func sepaAcceptViewController(_ viewController: SepaAcceptViewController, userInfo:[String:Any]?)
}


/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaAcceptViewController: UIHostingController<SepaAcceptView> {
    public weak var delegate: SepaAcceptViewControllerDelegate?

    private var completionHandler: ((RawResult<CheckoutProcess, SnabbleError>) -> Void)?
    private var cancellables = Set<AnyCancellable>()

    public var viewModel: SepaAcceptModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaAcceptModel, completion: @escaping (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {
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
                if let handler = completionHandler {
                    try await model.accept(completion: handler)
                }

                DispatchQueue.main.async {
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = AlertView(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.encryptionError"))
                    
                    alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default))
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
                
            default:
                print("unahndled action: \(action)")
                break
            }
        }
    }
    
    @objc
    private func dismiss() {
        dismiss(animated: true)
    }
}
