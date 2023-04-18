//
//  TeleCashCreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit
import SnabbleCore

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

    private var webView: WKWebView?
    private let spinner = UIActivityIndicatorView()

    private var detail: PaymentMethodDetail?
    private var brand: CreditCardBrand?
    private var ccNumber: String?
    private var expDate: String?
    private var projectId: Identifier<Project>?
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var vaultItem: TelecashVaultItem?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId

        super.init(nibName: nil, bundle: nil)
    }

    init(_ detail: PaymentMethodDetail, _ analyticsDelegate: AnalyticsDelegate?) {
        if case .teleCashCreditCard(let data) = detail.methodData {
            self.brand = data.brand
            self.ccNumber = data.displayName
            self.expDate = data.expirationDate
            self.detail = detail
        }
        self.analyticsDelegate = analyticsDelegate
        self.projectId = nil

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

        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        self.webView = webView
        view.addSubview(webView)

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

            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let userContentController = webView?.configuration.userContentController
        userContentController?.add(self, name: "save")
        userContentController?.add(self, name: "fail")
        userContentController?.add(self, name: "abort")

        if let brand = self.brand {
            self.title = brand.displayName
        } else {
            self.title = Asset.localizedString(forKey: "Snabble.Payment.creditCard")
        }

        if self.ccNumber != nil {
            self.webView?.isHidden = true

            self.cardNumber.text = self.ccNumber
            self.expirationDate.text = self.expDate

            self.cardNumberLabel.text = Asset.localizedString(forKey: "Snabble.CC.cardNumber")
            self.expDateLabel.text = Asset.localizedString(forKey: "Snabble.CC.validUntil")
            self.explanation.text = Asset.localizedString(forKey: "Snabble.CC.editingHint")

            let deleteButton = UIBarButtonItem(image: Asset.image(named: "trash"), style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let userContentController = webView?.configuration.userContentController
        userContentController?.removeScriptMessageHandler(forName: "save")
        userContentController?.removeScriptMessageHandler(forName: "fail")
        userContentController?.removeScriptMessageHandler(forName: "abort")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            self.detail == nil,
            let brand = self.brand,
            let projectId = self.projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == brand.method })
        else {
            return
        }

        if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
            loadForm(withProjectId: projectId, forCreditCardBrand: brand)
        } else {
            // oops - somehow we got here for a non-IPG tokenization. Bail out.
            showError()
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    private func loadForm(withProjectId projectId: Identifier<Project>, forCreditCardBrand creditCardBrand: CreditCardBrand) {
        var urlComponents = URLComponents(string: "\(Snabble.shared.environment.urlString)/\(projectId)/telecash/form")
        urlComponents?.queryItems = [
            .init(name: "platform", value: "ios"),
            .init(name: "paymentMethod", value: creditCardBrand.rawValue)
        ]
        if let appUserId = Snabble.shared.appUserId?.value {
            urlComponents?.queryItems?.append(.init(name: "appUserID", value: appUserId))
        }
        guard let url = urlComponents?.url else {
            return
        }

        let urlRequest = URLRequest(url: url)
        self.webView?.load(urlRequest)
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

extension TeleCashCreditCardEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension TeleCashCreditCardEditViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "save":
            save(message.body)
        case "fail":
            fail()
        case "abort":
            abort()
        default:
            fail()
        }
    }

    private func save(_ jsonObject: Any) {
        guard
            let projectId = self.projectId,
            let cert = Snabble.shared.certificates.first else {
                return showError()
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
            let connectGatewayReponse = try JSONDecoder().decode(ConnectGatewayResponse.self, from: jsonData)
            if let ccData = TeleCashCreditCardData(connectGatewayReponse, projectId, certificate: cert.data) {
                let detail = PaymentMethodDetail(ccData)
                PaymentMethodDetails.save(detail)
                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
                goBack()
            } else {
                Snabble.shared.project(for: projectId)?.logError("can't create CC data from IPG response: \(connectGatewayReponse)")
                showError()
            }
        } catch {
            showError()
        }
    }

    private func fail() {
        showError()
    }

    private func abort() {
        goBack()
    }

    private func showError() {
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }
}
