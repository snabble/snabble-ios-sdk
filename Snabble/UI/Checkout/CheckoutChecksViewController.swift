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

    let qrCodeContent: String

    init(qrCodeContent: String) {
        self.qrCodeContent = qrCodeContent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let qrCodeImage = QRCode.generate(for: qrCodeContent, scale: 5)
        let qrCodeImageView = UIImageView(image: qrCodeImage)
        qrCodeImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        qrCodeImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [qrCodeImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        view.addSubview(stackView)

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTouchedUpInside(_:)), for: .touchUpInside)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            cancelButton.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            view.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: cancelButton.trailingAnchor, multiplier: 1),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cancelButton.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor)
        ])

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc
    private func cancelButtonTouchedUpInside(_ sender: UIButton) {
        print(#function)
    }
}
