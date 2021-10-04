//
//  CheckoutStatusView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit

public final class CheckoutStatusView: UIView {
    public enum Status {
        case loading
        case success
        case failure
    }

    private(set) weak var circleView: CircleView?
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?
    private(set) weak var imageView: UIImageView?
    private(set) weak var textLabel: UILabel?

    override public init(frame: CGRect) {

        let circleView = CircleView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.circleColor = .gray

        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicatorView = UIActivityIndicatorView(style: .gray)
        }
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = .label

        super.init(frame: frame)

        backgroundColor = .systemBackground

        addSubview(circleView)
        addSubview(activityIndicatorView)
        addSubview(imageView)
        addSubview(textLabel)

        self.circleView = circleView
        self.activityIndicatorView = activityIndicatorView
        self.imageView = imageView
        self.textLabel = textLabel

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),

            circleView.widthAnchor.constraint(equalToConstant: 168).usingPriority(.defaultLow + 1),
            circleView.widthAnchor.constraint(equalTo: circleView.heightAnchor),
            circleView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            trailingAnchor.constraint(greaterThanOrEqualTo: circleView.trailingAnchor, constant: 32),

            activityIndicatorView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),

            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: circleView.leadingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: circleView.topAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 90),
            circleView.trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor),
            circleView.bottomAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor),

            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 16),

            circleView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            textLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 32),
            bottomAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with status: Status) {
        textLabel?.text = status.text
        circleView?.circleColor = status.circleColor
        imageView?.image = status.image

        switch status {
        case .loading:
            activityIndicatorView?.startAnimating()
        case .failure, .success:
            activityIndicatorView?.stopAnimating()
        }
    }
}

extension CheckoutStatusView.Status {
    var text: String {
        switch self {
        case .loading:
            return L10n.Snabble.Payment.waiting
        case .success:
            return L10n.Snabble.Payment.success
        case .failure:
            return L10n.Snabble.Payment.rejected
        }
    }

    var circleColor: UIColor? {
        switch self {
        case .loading:
            return .systemGray2
        case .success:
            return .systemGreen
        case .failure:
            return .systemRed
        }
    }

    var image: UIImage? {
        switch self {
        case .loading:
            return nil
        case .success:
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "checkmark")
            } else {
                return Asset.successIcon.image
            }
        case .failure:
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "xmark")
            } else {
                return nil // Warning: Missing Icon
            }
        }
    }
}
