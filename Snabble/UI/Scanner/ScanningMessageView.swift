//
//  ScanningMessageView.swift
//  Snabble
//
//  Created by Anastasia Mishur on 29.04.22.
//

import UIKit

protocol ScanningMessageViewViewProvider {
    var messages: [ScanMessage] { get }
}

final class ScanningMessageView: UIView {

    private(set) weak var stackView: UIStackView?
    private(set) weak var closeButton: UIButton?

    override init(frame: CGRect) {
        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        closeButton.setImage(image, for: .normal)
        closeButton.isUserInteractionEnabled = false
        closeButton.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.alignment = .fill

        super.init(frame: frame)

        backgroundColor = Assets.Color.systemBackground()

        addSubview(closeButton)
        addSubview(stackView)

        self.closeButton = closeButton
        self.stackView = stackView

        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
            closeButton.widthAnchor.constraint(lessThanOrEqualToConstant: 44),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).usingPriority(.defaultLow + 1),
            closeButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8).usingPriority(.defaultLow + 1),
            bottomAnchor.constraint(greaterThanOrEqualTo: closeButton.bottomAnchor, constant: 8),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with provider: ScanningMessageViewViewProvider) {
        let messages = provider.messages
        stackView?.removeAllArrangedSubviews()
        for (index, item) in messages.enumerated() {
            let view = MessageView(frame: .zero)
            if let attributedString = item.attributedString {
                view.label?.attributedText = attributedString
            } else {
                view.label?.text = item.text
            }
            if let imgUrl = item.imageUrl, let url = URL(string: imgUrl) {
                self.loadMessageImage(from: url, at: view)
            } else {
                view.imageView?.isHidden = true
            }

            if index > 0 {
                stackView?.addArrangedSubview(SeparatorView(frame: .zero))
            }
            stackView?.addArrangedSubview(view)

        }
        layoutIfNeeded()
    }

    private func loadMessageImage(from url: URL, at view: MessageView) {
        let session = Snabble.urlSession
        view.activityIndicatorView?.startAnimating()
        let task = session.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    view.activityIndicatorView?.stopAnimating()
                    view.imageView?.image = img
                }
            } else {
                DispatchQueue.main.async {
                    view.activityIndicatorView?.stopAnimating()
                    view.imageView?.isHidden = true
                }
            }
        }
        task.resume()
    }

    struct Provider: ScanningMessageViewViewProvider {
        var messages: [ScanMessage]

        init(messages: [ScanMessage]) {
            self.messages = messages
        }
    }
}

extension ScanningMessageView {
    final class SeparatorView: UIView {
        override init(frame: CGRect) {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = Assets.Color.separator()

            super.init(frame: frame)

            addSubview(view)

            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16),

                view.topAnchor.constraint(equalTo: topAnchor),
                view.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
                bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    final class MessageView: UIView {
        private(set) weak var imageView: UIImageView?
        private(set) weak var label: UILabel?
        private(set) weak var activityIndicatorView: UIActivityIndicatorView?

        override init(frame: CGRect) {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

            let activityIndicatorView = UIActivityIndicatorView(style: .medium)
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            activityIndicatorView.hidesWhenStopped = true

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = Assets.Color.label()
            label.textAlignment = .natural
            label.numberOfLines = 0
            label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

            let stackView = UIStackView(arrangedSubviews: [label, imageView])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.distribution = .fill
            stackView.alignment = .center

            super.init(frame: frame)

            addSubview(stackView)
            addSubview(activityIndicatorView)

            self.imageView = imageView
            self.activityIndicatorView = activityIndicatorView
            self.label = label

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),

                imageView.widthAnchor.constraint(equalToConstant: 80).usingPriority(.defaultHigh + 1),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).usingPriority(.defaultHigh + 1),

                activityIndicatorView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                activityIndicatorView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
