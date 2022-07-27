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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(Asset.SnabbleSDK.iconClose.image, for: .normal)
        closeButton.isUserInteractionEnabled = false

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.alignment = .fill

        addSubview(closeButton)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            closeButton.widthAnchor.constraint(equalToConstant: 33),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 2),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.stackView = stackView
    }

    public func configure(with provider: ScanningMessageViewViewProvider) {
        let messages = provider.messages
        stackView?.removeAllArrangedSubviews()
        for item in messages {
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

            stackView?.addArrangedSubview(view)
        }
        layoutIfNeeded()
    }

    private func loadMessageImage(from url: URL, at view: MessageView) {
        let session = Snabble.urlSession
        view.spinner?.startAnimating()
        let task = session.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    view.spinner?.stopAnimating()
                    view.imageView?.image = img
                }
            } else {
                DispatchQueue.main.async {
                    view.spinner?.stopAnimating()
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
    final class MessageView: UIView {
        private(set) weak var imageView: UIImageView?
        private(set) weak var label: UILabel?
        private(set) weak var spinner: UIActivityIndicatorView?

        override init(frame: CGRect) {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

            let spinner = UIActivityIndicatorView()
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.hidesWhenStopped = true
            if #available(iOS 13.0, *) {
                spinner.style = .medium
            } else {
                spinner.style = .gray
            }

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = .label
            label.textAlignment = .natural
            label.numberOfLines = 0
            label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

            let separator = UIView()
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.backgroundColor = .separator

            let stackView = UIStackView(arrangedSubviews: [label, imageView])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.distribution = .fill
            stackView.alignment = .center

            super.init(frame: frame)

            addSubview(stackView)
            addSubview(spinner)
            addSubview(separator)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

                imageView.widthAnchor.constraint(equalToConstant: 80).usingPriority(.defaultHigh + 1),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).usingPriority(.defaultHigh + 1),

                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),

                spinner.topAnchor.constraint(equalTo: imageView.topAnchor),
                spinner.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
                spinner.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                spinner.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
            ])

            self.imageView = imageView
            self.spinner = spinner
            self.label = label
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
