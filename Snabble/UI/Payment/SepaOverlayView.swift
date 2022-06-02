//
//  SepaOverlayView.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

public protocol SepaOverlayViewModel {
    var title: String { get }
    var text: NSAttributedString { get }

    var successButtonTitle: String { get }
}

public final class SepaOverlayView: UIView {
    private(set) var titleLabel: UILabel?
    public private(set) var textLabel: UILabel?
    public private(set) var successButton: UIButton?
    public private(set) var closeButton: UIButton?

    private weak var stackView: UIStackView?

    override public init(frame: CGRect) {
        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(Asset.SnabbleSDK.iconClose.image, for: .normal)

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let textLabel = UILabel()
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20

        let successButton = UIButton(type: .system)
        successButton.translatesAutoresizingMaskIntoConstraints = false
        successButton.preferredFont(forTextStyle: .headline)
        successButton.layer.cornerRadius = 8
        successButton.makeSnabbleButton()

        super.init(frame: frame)

        backgroundColor = .systemBackground

        addSubview(closeButton)
        addSubview(stackView)
        addSubview(successButton)

        self.closeButton = closeButton
        self.stackView = stackView
        self.titleLabel = titleLabel
        self.textLabel = textLabel
        self.successButton = successButton

        let layoutGuide = UILayoutGuide()
        addLayoutGuide(layoutGuide)

        NSLayoutConstraint.activate([
            layoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: layoutGuide.trailingAnchor, multiplier: 2),

            layoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: layoutGuide.bottomAnchor, multiplier: 2),

            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor),
            closeButton.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 33),

            stackView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            successButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: successButton.trailingAnchor),
            successButton.heightAnchor.constraint(equalToConstant: 48),

            closeButton.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: closeButton.bottomAnchor, multiplier: 1),
            successButton.topAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 2),
            layoutGuide.bottomAnchor.constraint(equalTo: successButton.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8
    }

    public func configure(with viewModel: SepaOverlayViewModel) {
        titleLabel?.text = viewModel.title
        textLabel?.attributedText = viewModel.text

        successButton?.setTitle(viewModel.successButtonTitle, for: .normal)
    }

    public struct ViewModel: SepaOverlayViewModel {
        public let title: String = L10n.Snabble.Sepa.mandate
        public let text: NSAttributedString

        public let successButtonTitle: String = L10n.Snabble.Sepa.iAgree

        public init(project: Project?) {
            let text = project?.messages?.sepaMandateShort ?? ""
            var attributedString = NSAttributedString(string: text)

            // swiftlint:disable:next force_try
            let regex = try! NSRegularExpression(pattern: "^(.*?)\\*(.*)\\*(.*?)$", options: .caseInsensitive)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            if !matches.isEmpty && matches[0].numberOfRanges == 4 {
                let str = NSMutableAttributedString()

                for idx in 1 ..< matches[0].numberOfRanges {
                    let range = matches[0].range(at: idx)
                    let startIndex = text.index(text.startIndex, offsetBy: range.lowerBound)
                    let endIndex = text.index(text.startIndex, offsetBy: range.upperBound)
                    let substr = String(text[startIndex..<endIndex])

                    let attributes: [NSAttributedString.Key: Any]? = idx == 2 ? [
                        .foregroundColor: UIColor.label,
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ] : nil
                    str.append(NSAttributedString(string: substr, attributes: attributes))
                }
                attributedString = str
            }
            self.text = attributedString
        }
    }
}
