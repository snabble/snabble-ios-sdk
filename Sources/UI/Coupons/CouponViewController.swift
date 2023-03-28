//
//  CouponViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit
import SnabbleCore

public protocol CouponViewControllerDelegate: AnyObject {
    func couponViewController(_ couponViewController: CouponViewController, shouldActivateCoupon: Coupon) -> Bool
    func couponViewController(_ couponViewController: CouponViewController, didActivateCoupon: Coupon)
}

public final class CouponViewController: UIViewController {
    private(set) weak var imageBackgroundView: UIView?
    private(set) weak var imageView: UIImageView?
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?

    private(set) weak var scrollView: UIScrollView?
    private(set) weak var stackView: UIStackView?
    private(set) weak var titleLabel: UILabel?
    private(set) weak var subtitleLabel: UILabel?
    private(set) weak var textLabel: UILabel?
    private(set) weak var validityLabel: UILabel?
    private(set) weak var disclaimerLabel: UILabel?

    private(set) weak var button: UIButton?
    private(set) weak var activatedStackView: UIView?

    private let couponViewModel: CouponViewModel

    private var sessionDataTask: URLSessionDataTask?

    private(set) var coupon: Coupon
    public weak var delegate: CouponViewControllerDelegate?

    public init(coupon: Coupon) {
        self.coupon = coupon
        self.couponViewModel = CouponViewModel(coupon: coupon)
        super.init(nibName: nil, bundle: nil)

        title = Asset.localizedString(forKey: "Snabble.Coupons.title")
        view.backgroundColor = .systemBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sessionDataTask?.cancel()
    }

    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        self.scrollView = scrollView

        let imageBackgroundView = UIView()
        imageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageBackgroundView)
        self.imageBackgroundView = imageBackgroundView

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageBackgroundView.addSubview(imageView)
        self.imageView = imageView

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        imageBackgroundView.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .title2, weight: .bold)
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        self.subtitleLabel = subtitleLabel

        let disclaimerLabel = UILabel()
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.font = .preferredFont(forTextStyle: .subheadline)
        self.disclaimerLabel = disclaimerLabel

        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.font = .preferredFont(forTextStyle: .headline)
        textLabel.textColor = .accent()
        self.textLabel = textLabel

        let validityLabel = UILabel()
        validityLabel.font = .preferredFont(forTextStyle: .caption1)
        validityLabel.numberOfLines = 0
        self.validityLabel = validityLabel

        let button = UIButton(type: .system)
        button.setTitle(Asset.localizedString(forKey: "Snabble.Coupon.activate"), for: .normal)
        button.setBackgroundColor(color: .accent(), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.tintColor = .onAccent()
        button.addTarget(self, action: #selector(activateCoupon), for: .touchUpInside)
        self.button = button

        let greenColor = UIColor.systemGreen()
        let image = UIImage(systemName: "checkmark.circle")
        let checkMarkImageView = UIImageView(image: image)
        checkMarkImageView.tintColor = greenColor
        let activatedTextLabel = UILabel()
        activatedTextLabel.font = .preferredFont(forTextStyle: .title1)
        activatedTextLabel.text = Asset.localizedString(forKey: "Snabble.Coupon.activated")
        activatedTextLabel.textColor = greenColor
        activatedTextLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        let activatedStackView = UIStackView(arrangedSubviews: [checkMarkImageView, activatedTextLabel])
        activatedStackView.translatesAutoresizingMaskIntoConstraints = false
        activatedStackView.spacing = 4
        activatedStackView.axis = .horizontal
        activatedStackView.isHidden = true
        self.activatedStackView = activatedStackView

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, disclaimerLabel, textLabel, validityLabel, button, activatedStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.setCustomSpacing(32, after: disclaimerLabel)
        stackView.setCustomSpacing(8, after: textLabel)
        stackView.setCustomSpacing(32, after: validityLabel)
        scrollView.addSubview(stackView)
        self.stackView = stackView

        let contentLayoutGuide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            imageBackgroundView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            imageBackgroundView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            imageBackgroundView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            imageBackgroundView.heightAnchor.constraint(equalTo: imageBackgroundView.widthAnchor, multiplier: 9 / 16),

            imageView.centerXAnchor.constraint(equalTo: imageBackgroundView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageBackgroundView.centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: imageBackgroundView.topAnchor, constant: 32),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: imageBackgroundView.bottomAnchor, constant: -32),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageBackgroundView.leadingAnchor, constant: 32),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: imageBackgroundView.trailingAnchor, constant: -32),

            activityIndicatorView.centerXAnchor.constraint(equalTo: imageBackgroundView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageBackgroundView.centerYAnchor),

            stackView.topAnchor.constraint(equalTo: imageBackgroundView.bottomAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -16),

            button.heightAnchor.constraint(equalToConstant: 48),
            checkMarkImageView.heightAnchor.constraint(equalTo: checkMarkImageView.widthAnchor)
        ])

        self.view = view
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configure(with: couponViewModel)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let mask = CAShapeLayer()
        let path = UIBezierPath(
            roundedRect: button?.bounds ?? .zero,
            byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 8, height: 8)
        )
        mask.path = path.cgPath
        button?.layer.mask = mask
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verifyButtonState(of: button)
    }

    private func configure(with viewModel: CouponViewModel) {
        titleLabel?.text = viewModel.title
        subtitleLabel?.text = viewModel.subtitle
        textLabel?.text = viewModel.text
        validityLabel?.text = viewModel.validUntil
        disclaimerLabel?.text = viewModel.disclaimer

        imageBackgroundView?.backgroundColor = viewModel.coupon.backgroundColor

        activityIndicatorView?.startAnimating()
        sessionDataTask = viewModel.loadImage { [weak self] image in
            self?.activityIndicatorView?.stopAnimating()
            self?.imageView?.image = image
        }
    }

    private func verifyButtonState(of button: UIButton?) {
        button?.isHidden = coupon.isActivated
        activatedStackView?.isHidden = !coupon.isActivated
    }

    @objc
    private func activateCoupon(_ sender: UIButton) {
        guard delegate?.couponViewController(self, shouldActivateCoupon: coupon) ?? true else {
            return
        }
        Snabble.shared.couponManager.activate(coupon: coupon)
        verifyButtonState(of: button)

        delegate?.couponViewController(self, didActivateCoupon: coupon)
    }
}
