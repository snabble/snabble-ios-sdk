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

    public private(set) weak var circleView: CircleView?
    public private(set) weak var activityIndicatorView: UIActivityIndicatorView?
    public private(set) weak var imageView: UIImageView?

    var circleColor: UIColor? {
        get {
            circleView?.circleColor
        }
        set {
            circleView?.circleColor = newValue
        }
    }

    override public init(frame: CGRect) {
        let circleView = CircleView()
        circleView.translatesAutoresizingMaskIntoConstraints = false

        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicatorView = UIActivityIndicatorView(style: .gray)
        }
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .systemGray

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white

        super.init(frame: frame)

        backgroundColor = .systemBackground

        addSubview(circleView)
        addSubview(activityIndicatorView)
        addSubview(imageView)

        self.circleView = circleView
        self.activityIndicatorView = activityIndicatorView
        self.imageView = imageView

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),

            circleView.widthAnchor.constraint(equalTo: circleView.heightAnchor),
            circleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: circleView.trailingAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),

            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: circleView.leadingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: circleView.topAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            imageView.heightAnchor.constraint(equalTo: circleView.heightAnchor, multiplier: 0.55),
            circleView.trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor),
            circleView.bottomAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor),

            circleView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: circleView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with status: Status) {
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
    var circleColor: UIColor? {
        switch self {
        case .loading:
            return .clear
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
                return Asset.SnabbleSDK.checkmark.image
            }
        case .failure:
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "xmark")
            } else {
                return Asset.SnabbleSDK.x.image
            }
        }
    }
}
