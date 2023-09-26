//
//  TeleCashCreditCardAddViewController.swift
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

public final class TeleCashCreditCardAddViewController: UIViewController {
    private weak var explanationLabel: UILabel?
    private weak var webView: WKWebView?
    private weak var activityIndicatorView: UIActivityIndicatorView?

    private var brand: CreditCardBrand?
    private var projectId: Identifier<Project>

    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        super.init(nibName: nil, bundle: nil)
        title = brand?.displayName ?? Asset.localizedString(forKey: "Snabble.Payment.creditCard")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        view.backgroundColor = .systemBackground

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
        self.webView = webView

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView

        let explanationLabel = UILabel()
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.numberOfLines = 0
        explanationLabel.font = .preferredFont(forTextStyle: .footnote)
        explanationLabel.adjustsFontForContentSizeCategory = true
        view.addSubview(explanationLabel)
        self.explanationLabel = explanationLabel

        NSLayoutConstraint.activate([
            explanationLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            webView.topAnchor.constraint(equalToSystemSpacingBelow: explanationLabel.bottomAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: webView.bottomAnchor, multiplier: 1),

            explanationLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            explanationLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        self.view = view
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let userContentController = webView?.configuration.userContentController
        userContentController?.add(self, name: "save")
        userContentController?.add(self, name: "fail")
        userContentController?.add(self, name: "abort")
        userContentController?.add(self, name: "preAuthInfo")
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let userContentController = webView?.configuration.userContentController
        userContentController?.removeScriptMessageHandler(forName: "save")
        userContentController?.removeScriptMessageHandler(forName: "fail")
        userContentController?.removeScriptMessageHandler(forName: "abort")
        userContentController?.removeScriptMessageHandler(forName: "preAuthInfo")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        analyticsDelegate?.track(.viewPaymentMethodDetail)

        guard
            let brand = brand,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == brand.method }),
            descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true
        else {
            return showError()
        }
        loadForm(withProjectId: project.id, forCreditCardBrand: brand)
    }

    private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    private func loadForm(withProjectId projectId: Identifier<Project>, forCreditCardBrand creditCardBrand: CreditCardBrand) {
        var urlComponents = URLComponents(string: "\(Snabble.shared.environment.apiURLString)/\(projectId)/telecash/form")
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

    private func threeDSecureHint(for projectId: Identifier<Project>?, preAuthInfo: PreAuthInfo) -> String {
        var name = "snabble"
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.numberStyle = .currency

        if let projectId = projectId, let project = Snabble.shared.project(for: projectId) {
            name = project.company?.name ?? project.name
            formatter.minimumFractionDigits = project.decimalDigits
            formatter.maximumFractionDigits = project.decimalDigits
            formatter.currencySymbol = project.currencySymbol
            formatter.locale = Locale(identifier: project.locale)
        }

        formatter.currencyCode = preAuthInfo.currency
        let chargeDecimal = Decimal(string: preAuthInfo.charge.replacingOccurrences(of: ",", with: "."))
        let chargeTotal = formatter.string(for: chargeDecimal) ?? "1,00 €"

        return Asset.localizedString(forKey: "Snabble.CC.3dsecureHint.retailerWithPrice", arguments: chargeTotal, name)
    }
}

extension TeleCashCreditCardAddViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension TeleCashCreditCardAddViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "save":
            save(message.body)
        case "fail":
            fail()
        case "abort":
            abort()
        case "preAuthInfo":
            preAuth(message.body)
        default:
            fail()
        }
    }

    private func save(_ jsonObject: Any) {
        guard let cert = Snabble.shared.certificates.first else {
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

    private func preAuth(_ jsonObject: Any) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
            let preAuthInfo = try JSONDecoder().decode(PreAuthInfo.self, from: jsonData)
            explanationLabel?.text = threeDSecureHint(for: projectId, preAuthInfo: preAuthInfo)
        } catch {
            explanationLabel?.text = threeDSecureHint(for: projectId, preAuthInfo: .mock)
        }
    }
}

private struct PreAuthInfo: Decodable {
    let charge: String
    let currency: String
}

extension PreAuthInfo {
    static var mock: Self {
        .init(charge: "1.00", currency: "EUR")
    }
}
