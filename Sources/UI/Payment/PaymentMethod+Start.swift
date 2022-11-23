//
//  PaymentMethod+Start.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

public final class PaymentMethodStartCheck {
    private var method: PaymentMethod
    private var detail: PaymentMethodDetail?
    private weak var presenter: UIViewController?
    public weak var messageDelegate: MessageDelegate?
    private var completionHandler: ((Bool) -> Void)?

    public init(for method: PaymentMethod,
                detail: PaymentMethodDetail?,
                on presenter: UIViewController) {
        self.method = method
        self.detail = detail
        self.presenter = presenter
    }

    public func startPayment(_ completion: @escaping (Bool) -> Void) {
        guard let presenter = presenter, method.canStart() else {
            completion(false)
            return
        }

        self.completionHandler = completion
        switch method {
        case .deDirectDebit:
            if case .payoneSepa(let _) = detail?.methodData {
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

        case .paydirektOneKlick:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.Paydirekt.payNow"), completion)

        case .twint:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.Twint.payNow"), completion)
        case .postFinanceCard:
            self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.PostFinanceCard.payNow"), completion)

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS, .applePay:
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
        self.requestBiometricAuthentication(on: presenter, reason: Asset.localizedString(forKey: "Snabble.SEPA.payNow"), completionHandler)
    }

    @objc private func sepaShowDetailsTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let msg = SnabbleCI.project.messages?.sepaMandate ?? ""
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.SEPA.mandate"), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
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
                let message = Asset.localizedString(forKey: "Snabble.Biometry.locked", arguments: name)
                self.messageDelegate?.showWarningMessage(message)
                completion(false)
            default:
                completion(false)
            }
        }
    }
}
