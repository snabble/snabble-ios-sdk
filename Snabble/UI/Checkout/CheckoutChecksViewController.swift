//
//  CheckoutChecksViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 18.11.21.
//

import Foundation
import UIKit

protocol CheckoutChecksViewControllerDelegate: AnyObject {
    func checkoutChecksViewControllerDidFinish(_ checksViewController: CheckoutChecksViewController)
}

final class CheckoutChecksViewController: UIViewController {

    private(set) weak var descriptionImageView: UIImageView?
    private(set) weak var textLabel: UILabel?
    private(set) weak var arrowImageView: UIImageView?
    private(set) weak var qrCodeImageView: UIImageView?
    private(set) weak var idLabel: UILabel?
    private(set) weak var cancelButton: UIButton?

    let checkoutProcessId: String
    let projectId: Identifier<Project>

    init(checkoutProcessId: String, projectId: Identifier<Project>) {
        self.checkoutProcessId = checkoutProcessId
        self.projectId = projectId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let descriptionImageView = UIImageView(image: nil)

        let textLabel = UILabel()
        textLabel.text = SnabbleAPI.l10n("Snabble.Payment.Online.message")
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center

        let arrowImageView = UIImageView(image: Asset.SnabbleSDK.arrowUp.image)
        arrowImageView.contentMode = .center

        let qrCodeImage = QRCode.generate(for: checkoutProcessId, scale: 5)
        let qrCodeImageView = UIImageView(image: qrCodeImage)
        qrCodeImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        qrCodeImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let idLabel = UILabel()
        idLabel.text = String(checkoutProcessId.suffix(4))
        idLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [descriptionImageView, textLabel, arrowImageView, qrCodeImageView, idLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        view.addSubview(stackView)

        self.descriptionImageView = descriptionImageView
        self.textLabel = textLabel
        self.arrowImageView = arrowImageView
        self.qrCodeImageView = qrCodeImageView
        self.idLabel = idLabel

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTouchedUpInside(_:)), for: .touchUpInside)
        view.addSubview(cancelButton)
        self.cancelButton = cancelButton

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            cancelButton.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            view.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: cancelButton.trailingAnchor, multiplier: 1),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.topAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor)
        ])

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SnabbleUI.getAsset(.checkoutOnline, bundlePath: "Checkout/\(projectId)/checkout-online") { [weak self] img in
            self?.descriptionImageView?.image = img
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        increaseBrightnessIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        resetBrightnessIfNeeded()
    }

    // MARK: Brightness
    
    private var previousBrightness: CGFloat?

    private func increaseBrightnessIfNeeded() {
        if UIScreen.main.brightness < 0.5 {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 0.5
        }
    }

    private func resetBrightnessIfNeeded() {
        if let previousBrightness = previousBrightness {
            UIScreen.main.brightness = previousBrightness
        }
        previousBrightness = nil
    }

    @objc
    private func cancelButtonTouchedUpInside(_ sender: UIButton) {
        print(#function)
    }
}
