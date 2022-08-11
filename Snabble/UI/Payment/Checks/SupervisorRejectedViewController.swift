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

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = Assets.Color.systemBackground()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false

        let stackViewLayout = UILayoutGuide()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 32

        let topIcon = UIImageView(image: Asset.SnabbleSDK.iconHintBig.image.withRenderingMode(.alwaysTemplate))
        topIcon.translatesAutoresizingMaskIntoConstraints = false
        topIcon.contentMode = .scaleAspectFit
        topIcon.tintColor = Assets.Color.label()
        topIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true
        topIcon.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        topIcon.setContentHuggingPriority(.defaultLow + 2, for: .vertical)

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = Assets.Color.label()
        messageLabel.font = Assets.preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        messageLabel.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        messageLabel.text = L10n.Snabble.Payment.rejectedHint

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.makeSnabbleButton()
        button.preferredFont(forTextStyle: .headline)
        button.setTitle(SnabbleSDK.L10n.Snabble.Payment.backToCart, for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped(_:)), for: .touchUpInside)

        contentView.addSubview(scrollView)
        scrollView.addSubview(wrapperView)

        wrapperView.addLayoutGuide(stackViewLayout)
        wrapperView.addSubview(stackView)
        wrapperView.addSubview(button)

        stackView.addArrangedSubview(topIcon)
        stackView.addArrangedSubview(messageLabel)

        NSLayoutConstraint.activate([
            frameLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            frameLayoutGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            frameLayoutGuide.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            frameLayoutGuide.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            frameLayoutGuide.widthAnchor.constraint(equalTo: contentLayoutGuide.widthAnchor),

            contentLayoutGuide.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor),
            contentLayoutGuide.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor),
            wrapperView.heightAnchor.constraint(greaterThanOrEqualTo: frameLayoutGuide.heightAnchor),

            button.heightAnchor.constraint(equalToConstant: 48),
            button.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -16),
            button.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 24),
            stackViewLayout.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -24),
            stackViewLayout.bottomAnchor.constraint(equalTo: button.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: stackViewLayout.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewLayout.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewLayout.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewLayout.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewLayout.bottomAnchor)
        ])

        self.view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Snabble.Payment.rejected
        self.navigationItem.hidesBackButton = true

        view.backgroundColor = Assets.Color.systemBackground()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)

        delegate?.track(.checkoutRejected)
    }

    @objc private func backButtonTapped(_ sender: UIButton) {
        guard let viewControllers = self.navigationController?.viewControllers, viewControllers.count > 2 else {
            return
        }

        // pop the last two VCs from the stack (this one and the payment progress)
        let target = viewControllers[viewControllers.count - 3]
        self.navigationController?.popToViewController(target, animated: true)
    }
}
