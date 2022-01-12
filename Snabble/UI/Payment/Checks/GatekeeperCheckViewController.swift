//
//  GatekeeperCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class GatekeeperCheckViewController: BaseCheckViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = L10n.Snabble.Payment.confirm + " GK"
    }

    override func renderCode(_ content: String) -> UIImage? {
        QRCode.generate(for: content, scale: 5)
    }

    override func arrangeLayout() {
        topWrapper.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topWrapper.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: topWrapper.bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: topWrapper.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(iconWrapper)
        stackView.addArrangedSubview(textWrapper)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeWrapper)
        stackView.addArrangedSubview(idWrapper)
    }
}
