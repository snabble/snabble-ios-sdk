//
//  CheckoutRatingViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 28.10.21.
//

import Foundation
import UIKit
import SDCAlertView
import StoreKit

final class CheckoutRatingViewController: UIViewController {
    private(set) weak var textLabel: UILabel?
    private(set) weak var detailTextLabel: UILabel?
    private(set) weak var leftButton: UIButton?
    private(set) weak var middleButton: UIButton?
    private(set) weak var rightButton: UIButton?

    enum State {
        case initial
        case finished
    }

    public let shop: Shop

    private weak var buttonStackView: UIStackView?

    public var shouldRequestReview = true
    public weak var analyticsDelegate: AnalyticsDelegate?

    var state: State = .initial {
        didSet {
            switch state {
            case .initial:
                detailTextLabel?.isHidden = true
                buttonStackView?.isHidden = false
            case .finished:
                detailTextLabel?.isHidden = false
                buttonStackView?.isHidden = true
            }
        }
    }

    init(shop: Shop) {
        self.shop = shop
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .systemFont(ofSize: 17)
        textLabel.numberOfLines = 1
        textLabel.minimumScaleFactor = 13.0 / 17.0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.lineBreakMode = .byTruncatingMiddle
        textLabel.textAlignment = .center
        textLabel.text = L10n.Snabble.PaymentStatus.Ratings.title

        let detailTextLabel = UILabel()
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        detailTextLabel.font = .systemFont(ofSize: 17)
        detailTextLabel.numberOfLines = 1
        detailTextLabel.minimumScaleFactor = 13.0 / 17.0
        detailTextLabel.adjustsFontSizeToFitWidth = true
        detailTextLabel.lineBreakMode = .byTruncatingMiddle
        detailTextLabel.textAlignment = .center
        detailTextLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        detailTextLabel.text = L10n.Snabble.PaymentStatus.Ratings.thanks
        detailTextLabel.isHidden = true

        let leftButton = UIButton(type: .system)
        leftButton.setImage(Asset.SnabbleSDK.emoji1.image, for: .normal)
        leftButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
        leftButton.tag = 1

        let middleButton = UIButton(type: .system)
        middleButton.setImage(Asset.SnabbleSDK.emoji2.image, for: .normal)
        middleButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
        middleButton.tag = 2

        let rightButton = UIButton(type: .system)
        rightButton.setImage(Asset.SnabbleSDK.emoji3.image, for: .normal)
        rightButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
        rightButton.tag = 3

        let buttonStackView = UIStackView(arrangedSubviews: [leftButton, middleButton, rightButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 22
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fillEqually

        view.addSubview(textLabel)
        view.addSubview(detailTextLabel)
        view.addSubview(buttonStackView)

        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.buttonStackView = buttonStackView

        self.leftButton = leftButton
        self.middleButton = middleButton
        self.rightButton = rightButton

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: view.topAnchor),
            detailTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 16),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: detailTextLabel.bottomAnchor),

            buttonStackView.topAnchor.constraint(equalTo: detailTextLabel.topAnchor),
            detailTextLabel.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor),

            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: textLabel.trailingAnchor),

            detailTextLabel.centerXAnchor.constraint(equalTo: textLabel.centerXAnchor),
            detailTextLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: detailTextLabel.trailingAnchor),

            buttonStackView.centerXAnchor.constraint(equalTo: textLabel.centerXAnchor),
            buttonStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: buttonStackView.trailingAnchor)
        ])

        self.view = view
    }

    @objc private func likeButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            self.getRatingComment(sender.tag)
        case 3:
            self.requestReview()
            fallthrough
        case 2:
            self.sendFeedback(sender.tag)
        default:
            break
        }
    }

    private func sendFeedback(_ rating: Int, _ comment: String? = nil) {
        guard let project = shop.project else {
            return
        }
        RatingEvent.track(project, rating, comment, shop.id)
        analyticsDelegate?.track(.ratingSubmitted(value: rating))

        state = .finished
    }

    private func getRatingComment(_ rating: Int) {
        let alert = AlertController(title: L10n.Snabble.PaymentStatus.Rating.title, message: nil, preferredStyle: .alert)
        alert.visualStyle = .snabbleAlert

        let textField = UITextView(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.becomeFirstResponder()

        alert.contentView.addSubview(textField)

        textField.centerXAnchor.constraint(equalTo: alert.contentView.centerXAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: alert.contentView.topAnchor).isActive = true
        textField.bottomAnchor.constraint(equalTo: alert.contentView.bottomAnchor).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 100).isActive = true
        textField.widthAnchor.constraint(equalToConstant: alert.visualStyle.width - 16).isActive = true

        alert.addAction(AlertAction(title: L10n.Snabble.cancel, style: .normal))
        alert.addAction(AlertAction(title: L10n.Snabble.PaymentStatus.Rating.send, style: .preferred) { _ in
            self.sendFeedback(rating, textField.text)
        })

        alert.present()
    }

    private func requestReview() {
        if #available(iOS 14.0, *), shouldRequestReview, let windowScene = self.view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
