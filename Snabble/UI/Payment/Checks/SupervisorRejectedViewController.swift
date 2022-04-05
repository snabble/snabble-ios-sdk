//
//  SupervisorRejectedViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class SupervisorRejectedViewController: UIViewController {
    private let process: CheckoutProcess?
    weak var delegate: AnalyticsDelegate?

    init(_ process: CheckoutProcess?) {
        self.process = process

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Snabble.Payment.rejected
        self.navigationItem.hidesBackButton = true

        view.backgroundColor = .systemBackground

        let topSpace = UIView()
        topSpace.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topSpace)

        let button = UIButton()
        button.makeSnabbleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(SnabbleSDK.L10n.Snabble.Payment.backToCart, for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            topSpace.topAnchor.constraint(equalTo: view.topAnchor),
            topSpace.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSpace.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topSpace.bottomAnchor.constraint(equalTo: button.topAnchor),

            button.heightAnchor.constraint(equalToConstant: 48),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 32

        let hintIcon = UIImageView(image: Asset.SnabbleSDK.iconHintBig.image.withRenderingMode(.alwaysTemplate))
        hintIcon.contentMode = .scaleAspectFit
        hintIcon.tintColor = .label
        stack.addArrangedSubview(hintIcon)

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = L10n.Snabble.Payment.rejectedHint

        stack.addArrangedSubview(label)
        topSpace.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: topSpace.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: topSpace.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: topSpace.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: topSpace.trailingAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)

        delegate?.track(.checkoutRejected)
    }

    @IBAction private func backButtonTapped(_ sender: UIButton) {
        guard let viewControllers = self.navigationController?.viewControllers, viewControllers.count > 2 else {
            return
        }

        // pop the last two VCs from the stack (this one and the payment progress)
        let target = viewControllers[viewControllers.count - 3]
        self.navigationController?.popToViewController(target, animated: true)
    }
}
