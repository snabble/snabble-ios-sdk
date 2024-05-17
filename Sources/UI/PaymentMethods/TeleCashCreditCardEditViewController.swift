//
//  TeleCashCreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit
import SnabbleCore
import SnabbleAssetProviding

// sample data for testing:
//
// Visa: 4242 4242 4242 4242, Expiry: any future date, CVV: any 3-digit number
// Mastercard: 5555 5555 5555 4444, Expiry: any future date, CVV: any 3-digit number
// Amex: 3714 4963 5398 431, Expiry: any future date, CVV: any 4-digit number
//
// see https://stripe.com/docs/testing

public final class TeleCashCreditCardEditViewController: UIViewController {
    private let explanation = UILabel()

    private let cardNumberLabel = UILabel()
    private let cardNumber = UITextField()

    private let expDateLabel = UILabel()
    private let expirationDate = UITextField()

    private let spinner = UIActivityIndicatorView()

    private var detail: PaymentMethodDetail?
    private var brand: CreditCardBrand?
    private var ccNumber: String?
    private var expDate: String?

    private weak var analyticsDelegate: AnalyticsDelegate?

    init(_ detail: PaymentMethodDetail, _ analyticsDelegate: AnalyticsDelegate?) {
        if case .teleCashCreditCard(let data) = detail.methodData {
            self.brand = data.brand
            self.ccNumber = data.displayName
            self.expDate = data.expirationDate
            self.detail = detail
        }
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stackView = UIStackView(arrangedSubviews: [
            explanation, cardNumberLabel, cardNumber, expDateLabel, expirationDate
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.setCustomSpacing(8, after: cardNumberLabel)
        stackView.setCustomSpacing(8, after: expDateLabel)
        scrollView.addSubview(stackView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        explanation.numberOfLines = 0
        explanation.font = .preferredFont(forTextStyle: .footnote)
        explanation.adjustsFontForContentSizeCategory = true

        cardNumberLabel.font = .preferredFont(forTextStyle: .body)
        cardNumberLabel.adjustsFontForContentSizeCategory = true

        cardNumber.font = .preferredFont(forTextStyle: .body)
        cardNumber.adjustsFontForContentSizeCategory = true
        cardNumber.isEnabled = false
        cardNumber.borderStyle = .roundedRect

        expDateLabel.font = .preferredFont(forTextStyle: .body)
        expDateLabel.adjustsFontForContentSizeCategory = true

        expirationDate.font = .preferredFont(forTextStyle: .body)
        expirationDate.adjustsFontForContentSizeCategory = true
        expirationDate.isEnabled = false
        expirationDate.borderStyle = .roundedRect

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),

            cardNumber.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            expirationDate.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let brand = self.brand {
            self.title = brand.displayName
        } else {
            self.title = Asset.localizedString(forKey: "Snabble.Payment.creditCard")
        }

        self.cardNumber.text = self.ccNumber
        self.expirationDate.text = self.expDate

        self.cardNumberLabel.text = Asset.localizedString(forKey: "Snabble.CC.cardNumber")
        self.expDateLabel.text = Asset.localizedString(forKey: "Snabble.CC.validUntil")
        self.explanation.text = Asset.localizedString(forKey: "Snabble.CC.editingHint")

        let deleteButton = UIBarButtonItem(image: Asset.image(named: "trash"), style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = deleteButton
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.Payment.Delete.message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.brand?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
