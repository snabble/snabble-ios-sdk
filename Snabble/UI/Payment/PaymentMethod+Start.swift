//
//  PaymentMethod+Start.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

public final class PaymentMethodStartCheck {
    private var method: PaymentMethod
    private weak var presenter: UIViewController?
    private weak var messageDelegate: MessageDelegate?
    private var completionHandler: ((Bool) -> Void)?

    public init(for method: PaymentMethod,
                on presenter: UIViewController,
                messageDelegate: MessageDelegate) {
        self.method = method
        self.presenter = presenter
        self.messageDelegate = messageDelegate
    }

    public func startPayment(_ completion: @escaping (Bool) -> Void) {
        guard let presenter = presenter else {
            completion(false)
            return
        }

        self.completionHandler = completion
        switch method {
        case .deDirectDebit:
            let view = SepaOverlayView(frame: .zero)
            let viewModel = SepaOverlayView.ViewModel(project: SnabbleUI.project, appearance: SnabbleUI.appearance)
            view.configure(with: viewModel)

            view.closeButton?.addTarget(self, action: #selector(dismissOverlay(_:)), for: .touchUpInside)
            view.successButton?.addTarget(self, action: #selector(sepaSuccessButtonTapped(_:)), for: .touchUpInside)

            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sepaShowDetailsTapped(_:)))
            view.textLabel?.addGestureRecognizer(tapGestureRecognizer)
            view.textLabel?.isUserInteractionEnabled = true

            presenter.showOverlay(with: view)

        case .visa, .mastercard, .americanExpress:
            self.requestBiometricAuthentication(on: presenter, reason: L10n.Snabble.CreditCard.payNow, completion)

        case .paydirektOneKlick:
            self.requestBiometricAuthentication(on: presenter, reason: L10n.Snabble.Paydirekt.payNow, completion)

        case .twint:
            self.requestBiometricAuthentication(on: presenter, reason: L10n.Snabble.Twint.payNow, completion)
        case .postFinanceCard:
            self.requestBiometricAuthentication(on: presenter, reason: L10n.Snabble.PostFinanceCard.payNow, completion)

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS, .applePay, .unknown:
            completion(true)
        }
    }

    // MARK: - Sepa
    @objc private func dismissOverlay(_ sender: Any) {
        presenter?.dismissOverlay()
        completionHandler?(false)
    }

    @objc private func sepaSuccessButtonTapped(_ sender: UIButton) {
        guard
            let presenter = presenter,
            let completionHandler = completionHandler
        else {
            return
        }

        presenter.dismissOverlay()
        self.requestBiometricAuthentication(on: presenter, reason: L10n.Snabble.Sepa.payNow, completionHandler)
    }

    @objc private func sepaShowDetailsTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let msg = SnabbleUI.project.messages?.sepaMandate ?? ""
        let alert = UIAlertController(title: L10n.Snabble.Sepa.mandate, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default, handler: nil))
        presenter?.present(alert, animated: true)
    }

    // MARK: - biometry

    private func requestBiometricAuthentication(on presenter: UIViewController, reason: String, _ completion: @escaping (Bool) -> Void) {
        BiometricAuthentication.requestAuthentication(for: reason) { result in
            switch result {
            case .proceed:
                completion(true)
            case .locked:
                let name = BiometricAuthentication.supportedBiometry.name
                let message = L10n.Snabble.Biometry.locked(name)
                self.messageDelegate?.showWarningMessage(message)
                completion(false)
            default:
                completion(false)
            }
        }
    }
}
