//
//  PaymentMethod+Start.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import Combine
import SnabbleAssetProviding

@MainActor
public final class PaymentMethodStartCheck {
    private var method: PaymentMethod
    private var detail: PaymentMethodDetail?
    private weak var presenter: UIViewController?
    public weak var messageDelegate: MessageDelegate?
    private var completionHandler: (@Sendable (Bool) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    public init(for method: PaymentMethod,
                detail: PaymentMethodDetail?,
                on presenter: UIViewController) {
        self.method = method
        self.detail = detail
        self.presenter = presenter
    }

    public func startPayment(_ completion: @escaping @Sendable (Bool) -> Void) {
        guard let presenter = presenter, method.canStart() else {
            completion(false)
            return
        }

        self.completionHandler = completion
        switch method {
        case .deDirectDebit:
            if case .payoneSepa = detail?.methodData {
                self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.SEPA.payNow"), completion)
            } else {
                    
                let view = SepaOverlayView(frame: .zero)
                let viewModel = SepaOverlayView.ViewModel(project: SnabbleCI.project)
                view.configure(with: viewModel)
                
                view.closeButton?.addTarget(self, action: #selector(dismissOverlay(_:)), for: .touchUpInside)
                view.successButton?.addTarget(self, action: #selector(sepaSuccessButtonTapped(_:)), for: .touchUpInside)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sepaShowDetailsTapped(_:)))
                view.textLabel?.addGestureRecognizer(tapGestureRecognizer)
                view.textLabel?.isUserInteractionEnabled = true
                
                presenter.showOverlay(with: view)
            }
            
        case .visa, .mastercard, .americanExpress:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.CreditCard.payNow"), completion)

        case .giropayOneKlick:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.Giropay.payNow"), completion)

        case .twint:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.Twint.payNow"), completion)
        case .postFinanceCard:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.PostFinanceCard.payNow"), completion)
        case .externalBilling:
            if let detail = self.detail, detail.originType == .contactPersonCredentials, case .invoiceByLogin = detail.methodData {
                let viewController = PaymentSubjectViewController()
                viewController.viewModel.actionPublisher
                    .receive(on: RunLoop.main)
                    .sink { [weak self] userDict in
                        self?.performAction(viewModel: viewController.viewModel, userDict: userDict)
                    }
                    .store(in: &cancellables)

                presenter.showOverlay(with: viewController)
            } else {
                completion(true)
            }
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS, .applePay:
            completion(true)
        }
    }
   
    private func performAction(viewModel: PaymentSubjectViewModel, userDict: [String: Any]?) {
        guard let presenter = self.presenter,
              let completionHandler = self.completionHandler,
              let action = userDict?["action"] as? String else {
            return
        }
        globalButterOverflow = nil
        if action == "add", let subject = viewModel.subject {
            globalButterOverflow = subject
        }
        presenter.dismissOverlay()
        self.requestBiometricAuthentication(
            on: presenter,
            reason: Asset.localizedString(forKey: "Snabble.ExternalBilling.payNow"),
            completionHandler
        )
    }

    // MARK: - Sepa
    @MainActor @objc private func dismissOverlay(_ sender: Any) {
        presenter?.dismissOverlay()
        completionHandler?(false)
    }

    @MainActor @objc private func sepaSuccessButtonTapped(_ sender: UIButton) {
        guard
            let presenter = presenter,
            let completionHandler = completionHandler
        else {
            return
        }

        presenter.dismissOverlay()
        self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.SEPA.payNow"), completionHandler)
    }

    @objc private func sepaShowDetailsTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let msg = SnabbleCI.project.messages?.sepaMandate ?? ""
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.SEPA.mandate"), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
        presenter?.present(alert, animated: true)
    }

    // MARK: - biometry

    private func requestBiometricAuthentication(on presenter: UIViewController, reason: String, _ completion: @escaping @Sendable (Bool) -> Void) {
        BiometricAuthentication.requestAuthentication(for: reason) { result in
            switch result {
            case .proceed:
                completion(true)
            case .locked:
                let name = BiometricAuthentication.supportedBiometry.name
                let message = Asset.localizedString(forKey: "Snabble.Biometry.locked", arguments: name)
                Task { @MainActor in
                    self.messageDelegate?.showWarningMessage(message)
                }
                completion(false)
            default:
                completion(false)
            }
        }
    }
}
