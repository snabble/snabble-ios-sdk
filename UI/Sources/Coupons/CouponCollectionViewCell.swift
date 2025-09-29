//
//  CouponCollectionViewCell.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.07.22.
//

import Foundation
import UIKit
import SnabbleAssetProviding

class CouponCollectionViewCell: UICollectionViewCell, Cardable, ReuseIdentifiable {
    private(set) weak var imageView: UIImageView?
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?
    private(set) weak var titleLabel: UILabel?
    private(set) weak var subtitleLabel: UILabel?
    private(set) weak var textLabel: UILabel?
    private(set) weak var validityLabel: UILabel?

    private var sessionDataTask: URLSessionDataTask?

    override init(frame: CGRect) {
        let imageGuide = UILayoutGuide()

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh + 3, for: .vertical)
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.adjustsFontSizeToFitWidth = true

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.minimumScaleFactor = 0.75
        subtitleLabel.adjustsFontSizeToFitWidth = true

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .preferredFont(forTextStyle: .headline)
        textLabel.textColor = .projectPrimary()
        textLabel.numberOfLines = 0
        textLabel.setContentCompressionResistancePriority(.defaultHigh + 2, for: .vertical)
        textLabel.minimumScaleFactor = 0.75
        textLabel.adjustsFontSizeToFitWidth = true

        let validityLabel = UILabel()
        validityLabel.translatesAutoresizingMaskIntoConstraints = false
        validityLabel.font = .preferredFont(forTextStyle: .caption1)
        validityLabel.numberOfLines = 0
        validityLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)
        validityLabel.minimumScaleFactor = 0.75
        validityLabel.adjustsFontSizeToFitWidth = true

        super.init(frame: frame)

        contentView.addLayoutGuide(imageGuide)

        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicatorView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(textLabel)
        contentView.addSubview(validityLabel)

        self.imageView = imageView
        self.activityIndicatorView = activityIndicatorView
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.textLabel = textLabel
        self.validityLabel = validityLabel

        NSLayoutConstraint.activate([
            imageGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageGuide.heightAnchor.constraint(equalToConstant: 200),

            imageView.centerXAnchor.constraint(equalTo: imageGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageGuide.centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: imageGuide.topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: imageGuide.bottomAnchor, constant: -16),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageGuide.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: imageGuide.trailingAnchor, constant: -16),

            activityIndicatorView.centerXAnchor.constraint(equalTo: imageGuide.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageGuide.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageGuide.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            textLabel.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 16),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            validityLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 8),
            validityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            validityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            validityLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        enableCardStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        sessionDataTask?.cancel()
        activityIndicatorView?.stopAnimating()

        imageView?.image = nil
        titleLabel?.text = nil
        subtitleLabel?.text = nil
        textLabel?.text = nil
        validityLabel?.text = nil
    }

    func configure(with couponViewModel: CouponViewModel) {
        titleLabel?.text = couponViewModel.title
        subtitleLabel?.text = couponViewModel.subtitle
        textLabel?.text = couponViewModel.text

        backgroundColor = couponViewModel.coupon.backgroundColor
        titleLabel?.textColor = couponViewModel.coupon.textColor
        subtitleLabel?.textColor = couponViewModel.coupon.textColor
        validityLabel?.textColor = couponViewModel.coupon.textColor

        validityLabel?.text = couponViewModel.validUntil

        imageView?.image = nil
        activityIndicatorView?.startAnimating()
        sessionDataTask = couponViewModel.loadImage { [weak self] image in
            Task { @MainActor in
                self?.activityIndicatorView?.stopAnimating()
                self?.imageView?.image = image
            }
        }
    }
}
