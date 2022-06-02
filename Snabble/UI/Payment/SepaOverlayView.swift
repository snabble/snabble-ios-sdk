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
        backgroundColor = .systemBackground
        if #available(iOS 15, *) {
            restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false

        let contentLayoutGuide = scrollView.contentLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(Asset.SnabbleSDK.iconClose.image, for: .normal)

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .body, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let textLabel = UILabel()
        textLabel.font = .preferredFont(forTextStyle: .body)
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
        successButton.makeSnabbleButton()

        let layoutGuide = UILayoutGuide()
        addLayoutGuide(layoutGuide)

        addSubview(closeButton)
        addSubview(scrollView)
        addSubview(successButton)

        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            layoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: layoutGuide.trailingAnchor, multiplier: 2),
            layoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: layoutGuide.bottomAnchor, multiplier: 2),

            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor),
            closeButton.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 33),

            scrollView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalToSystemSpacingBelow: closeButton.bottomAnchor, multiplier: 1),
            scrollView.widthAnchor.constraint(equalTo: contentLayoutGuide.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 0).usingPriority(.defaultHigh + 1).usingVariable(&scrollViewHeight),

            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentLayoutGuide.leadingAnchor, multiplier: 1),
            contentLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 1),
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),

            successButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            successButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            successButton.topAnchor.constraint(equalToSystemSpacingBelow: scrollView.bottomAnchor, multiplier: 2),
            successButton.heightAnchor.constraint(equalToConstant: 48),
            successButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        ])

        self.closeButton = closeButton
        self.stackView = stackView
        self.titleLabel = titleLabel
        self.textLabel = textLabel
        self.successButton = successButton
        self.scrollView = scrollView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8

        layoutScrollView()
    }

    private func layoutScrollView() {
        guard let scrollView = scrollView, let maxViewFrameHeight = maxViewFrameHeight else { return }
        let contentHeight = scrollView.contentLayoutGuide.layoutFrame.height
        scrollViewHeight?.constant = min(maxViewFrameHeight, contentHeight)
    }

    public func configure(with viewModel: SepaOverlayViewModel, for layoutGuide: UILayoutGuide) {
        titleLabel?.text = viewModel.title
        textLabel?.attributedText = viewModel.text

        successButton?.setTitle(viewModel.successButtonTitle, for: .normal)

        let height = layoutGuide.layoutFrame.height - 32
        maxViewFrameHeight = height > 0 ? height : nil
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
