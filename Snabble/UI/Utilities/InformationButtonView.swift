//
//  InformationButtonView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 17.12.20.
//

import Foundation
import UIKit

protocol InformationButtonViewModel {
    var title: String { get }
    var buttonTitle: String { get }
}

final class InformationButtonView: UIView {
    private(set) weak var titleLabel: UILabel?
    private(set) weak var button: UIButton?

    override init(frame: CGRect) {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, button])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frame)

        backgroundColor = .clear

        addSubview(stackView)

        self.titleLabel = titleLabel
        self.button = button

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.topAnchor),
            readableContentGuide.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor),
            readableContentGuide.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: InformationButtonViewModel) {
        titleLabel?.text = viewModel.title
        button?.setTitle(viewModel.buttonTitle, for: .normal)
    }

    struct ViewModel: InformationButtonViewModel {
        let title: String
        let buttonTitle: String
    }
}
