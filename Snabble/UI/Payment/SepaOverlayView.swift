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
    private weak var scrollView: UIScrollView?
    private var maxViewFrameHeight: CGFloat?
    private var scrollViewHeight: NSLayoutConstraint?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Assets.Color.systemBackground()
        if #available(iOS 15, *) {
            restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = Assets.Color.systemBackground()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false

        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .body, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = Assets.preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        let successButton = UIButton(type: .system)
        successButton.translatesAutoresizingMaskIntoConstraints = false
        successButton.preferredFont(forTextStyle: .headline)
        successButton.makeSnabbleButton()

        let layoutGuide = UILayoutGuide()
        addLayoutGuide(layoutGuide)

        addSubview(closeButton)
        addSubview(scrollView)
        addSubview(successButton)

        scrollView.addSubview(titleLabel)
        scrollView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            layoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: layoutGuide.trailingAnchor, multiplier: 2),

            layoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: layoutGuide.bottomAnchor, multiplier: 2),

            // Horizontal
            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor),
            closeButton.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),

            scrollView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),

            successButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            successButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),

            // Vertical
            closeButton.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 34),
            scrollView.topAnchor.constraint(equalToSystemSpacingBelow: closeButton.bottomAnchor, multiplier: 2),
            successButton.topAnchor.constraint(equalToSystemSpacingBelow: scrollView.bottomAnchor, multiplier: 2),
            successButton.heightAnchor.constraint(equalToConstant: 48),
            successButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),

            // ScrollView Horizontal
            titleLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            textLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),

            // ScrollView Vertical
            titleLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            textLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 2),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: textLabel.bottomAnchor),

            scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor).usingPriority(.defaultHigh - 1),
            scrollView.heightAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.heightAnchor)
        ])

        self.closeButton = closeButton
        self.titleLabel = titleLabel
        self.textLabel = textLabel
        self.successButton = successButton
        self.scrollView = scrollView
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
                        .foregroundColor: Assets.Color.label(),
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
