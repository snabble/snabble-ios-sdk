//
//  PayoneCreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit
import AutoLayout_Helper

// sample data for testing:
//
// Visa: 4012 0010 3714 1112, Expiry: any future date, CVV: any 3-digit number
// Mastercard: 5453 0100 0008 0200, Expiry: any future date, CVV: any 3-digit number
// Amex: 3400 0000 0001 114, Expiry: any future date, CVV: any 4-digit number
//
// 3DSecure password for all: 12345
//
// see https://docs.payone.com/display/public/PLATFORM/Testdata

// more docs: https://docs.payone.com/display/public/PLATFORM/Hosted-iFrame+Mode+-+Short+description

public final class PayoneCreditCardEditViewController: UIViewController {
    private let webViewContainer = UIView()
    private weak var activityIndicator: UIActivityIndicatorView?
    private var webView: WKWebView?

    private let displayContainer = UIView()
    private let cardNumberLabel = UILabel()
    private let cardNumber = UITextField()

    private let expDateLabel = UILabel()
    private let expirationDate = UITextField()

    private let explanation = UILabel()

    private static let handlerName = "callbackHandler"

    private var detail: PaymentMethodDetail?
    private var brand: CreditCardBrand?
    private var ccNumber: String?
    private var expDate: String?
    private var projectId: Identifier<Project>?

    private weak var pollTimer: Timer?
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var payoneTokenization: PayoneTokenization?
    private var payonePreAuthResult: PayonePreAuthResult?
    private var payoneResponse: PayoneResponse?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId

        super.init(nibName: nil, bundle: nil)
    }

    init(_ detail: PaymentMethodDetail, _ analyticsDelegate: AnalyticsDelegate?) {
        if case .payoneCreditCard(let data) = detail.methodData {
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

        self.setupView()

        if let brand = self.brand {
            self.title = brand.displayName
        } else {
            self.title = L10n.Snabble.Payment.creditCard
        }

        if self.ccNumber != nil {
            self.webViewContainer.isHidden = true
            self.displayContainer.isHidden = false

            self.cardNumber.text = self.ccNumber
            self.expirationDate.text = self.expDate

            self.cardNumberLabel.text = L10n.Snabble.Cc.cardNumber
            self.expDateLabel.text = L10n.Snabble.Cc.validUntil
            self.explanation.text = L10n.Snabble.Cc.editingHint

            let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        } else {
            self.webViewContainer.isHidden = false
            self.displayContainer.isHidden = true

            self.startCreditCardTokenization()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    // (re)start the tokenization process
    private func startCreditCardTokenization() {
        guard
            self.detail == nil,
            let brand = self.brand,
            let projectId = self.projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == brand.method })
        else {
            return
        }

        self.payoneTokenization = nil
        self.payonePreAuthResult = nil
        self.payoneResponse = nil
        self.pollTimer?.invalidate()

        self.activityIndicator?.startAnimating()

        if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
             tokenizeWithPayone(project, descriptor)
        } else {
            // oops - somehow we got here for a non-payone tokenization. Bail out.
            showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            // we're being popped - stop timer and break the retain cycle
            self.pollTimer?.invalidate()
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        }
    }

    // get the tokenization data and show the data entry form
    private func tokenizeWithPayone(_ project: Project, _ descriptor: PaymentMethodDescriptor) {
        let link = descriptor.links?.tokenization
        self.getPayoneTokenization(for: project, link) { [weak self] result in
            self?.activityIndicator?.stopAnimating()
            switch result {
            case .failure:
                let alert = UIAlertController(title: "Oops", message: L10n.Snabble.Cc.noEntryPossible, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
                    self?.goBack()
                })
                self?.present(alert, animated: true)
            case .success(let payoneTokenization):
                self?.payoneTokenization = payoneTokenization
                self?.prepareAndInjectPage(payoneTokenization)
            }
        }
    }

    private func goBack() {
        self.navigationController?.popViewController(animated: true)
    }

    private func threeDSecureHint(for projectId: Identifier<Project>?, tokenization: PayoneTokenization) -> String {
        var name = "snabble"
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.numberStyle = .currency
        fmt.currencyCode = tokenization.preAuthInfo.currency

        var amount = Decimal(tokenization.preAuthInfo.amount)
        if let projectId = self.projectId, let project = Snabble.shared.project(for: projectId) {
            name = project.company?.name ?? project.name
            fmt.minimumFractionDigits = project.decimalDigits
            fmt.maximumFractionDigits = project.decimalDigits

            fmt.locale = Locale(identifier: project.locale)

            let divider = pow(Decimal(10), project.decimalDigits)
            amount /= divider
        }
        let chargeTotal = fmt.string(for: amount)!

        return L10n.Snabble.Cc._3dsecureHint.retailerWithPrice(chargeTotal, name)
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        // container for the "display-only" mode
        displayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayContainer)
        NSLayoutConstraint.activate(displayContainer.constraintsForAnchoringTo(boundsOf: view))

        explanation.translatesAutoresizingMaskIntoConstraints = false
        explanation.numberOfLines = 0
        explanation.font = UIFont.preferredFont(forTextStyle: .footnote)
        explanation.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(explanation)

        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardNumberLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cardNumberLabel.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(cardNumberLabel)

        cardNumber.translatesAutoresizingMaskIntoConstraints = false
        cardNumber.isEnabled = false
        cardNumber.borderStyle = .roundedRect
        cardNumber.font = UIFont.preferredFont(forTextStyle: .body)
        cardNumber.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(cardNumber)

        expDateLabel.translatesAutoresizingMaskIntoConstraints = false
        expDateLabel.font = UIFont.preferredFont(forTextStyle: .body)
        expDateLabel.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(expDateLabel)

        expirationDate.translatesAutoresizingMaskIntoConstraints = false
        expirationDate.isEnabled = false
        expirationDate.borderStyle = .roundedRect
        expirationDate.font = UIFont.preferredFont(forTextStyle: .body)
        expirationDate.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(expirationDate)

        NSLayoutConstraint.activate([
            explanation.topAnchor.constraint(equalTo: displayContainer.topAnchor, constant: 16),
            explanation.leadingAnchor.constraint(equalTo: displayContainer.leadingAnchor, constant: 16),
            explanation.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor, constant: -16),

            cardNumberLabel.topAnchor.constraint(equalTo: explanation.bottomAnchor, constant: 16),
            cardNumberLabel.leadingAnchor.constraint(equalTo: displayContainer.leadingAnchor, constant: 16),
            cardNumberLabel.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor, constant: -16),

            cardNumber.topAnchor.constraint(equalTo: cardNumberLabel.bottomAnchor, constant: 8),
            cardNumber.leadingAnchor.constraint(equalTo: displayContainer.leadingAnchor, constant: 16),
            cardNumber.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor, constant: -16),
            cardNumber.heightAnchor.constraint(equalToConstant: 40),

            expDateLabel.topAnchor.constraint(equalTo: cardNumber.bottomAnchor, constant: 16),
            expDateLabel.leadingAnchor.constraint(equalTo: displayContainer.leadingAnchor, constant: 16),
            expDateLabel.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor, constant: -16),

            expirationDate.topAnchor.constraint(equalTo: expDateLabel.bottomAnchor, constant: 8),
            expirationDate.leadingAnchor.constraint(equalTo: displayContainer.leadingAnchor, constant: 16),
            expirationDate.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor, constant: -16),
            expirationDate.heightAnchor.constraint(equalToConstant: 40)
        ])

        // container for our webview
        webViewContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webViewContainer)
        NSLayoutConstraint.activate(webViewContainer.constraintsForAnchoringTo(boundsOf: view))

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = Assets.Color.systemGray()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        webViewContainer.addSubview(activityIndicator)
        NSLayoutConstraint.activate(
            activityIndicator.constraintsForCenterIn(boundsOf: webViewContainer)
        )
        self.activityIndicator = activityIndicator

        setupWebView(in: webViewContainer)
    }

    private func setupWebView(in containerView: UIView) {
        let contentController = WKUserContentController()
        contentController.add(self, name: Self.handlerName)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(webView)
        NSLayoutConstraint.activate(webView.constraintsForAnchoringTo(boundsOf: containerView))

        self.webView = webView
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: L10n.Snabble.Payment.Delete.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.yes, style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.brand?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: L10n.Snabble.no, style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    // handle the response data we get from the payone web form. if the response is OK, start the pre-auth process
    private func processResponse(_ response: [String: Any], _ lastname: String?) {
        guard
            let projectId = self.projectId,
            let project = Snabble.shared.project(for: projectId),
            let lastname = lastname,
            let response = PayoneResponse(response: response, lastname: lastname)
        else {
            return
        }

        startPayonePreauthorization(for: project, payoneTokenization?.links.preAuth, response) { result in
            switch result {
            case .failure(let error):
                print(error)
                self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
            case .success(let preAuthResult):
                self.loadScaChallenge(for: project, preAuthResult, response)
            }
        }
    }

    // load the "SCA challenge" URL in our webview, and start polling the preAuth's status
    private func loadScaChallenge(for project: Project, _ preAuthResult: PayonePreAuthResult, _ response: PayoneResponse) {
        guard
            let url = URL(string: preAuthResult.links.scaChallenge.href)
        else {
            self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
            return
        }

        let scaRequest = URLRequest(url: url)
        self.webView?.load(scaRequest)

        self.payonePreAuthResult = preAuthResult
        self.payoneResponse = response

        self.startPreAuthPollTimer(for: project, preAuthResult)
    }

    // schedule a timer to get the preAuth status in 1 sec.
    // continue polling if the status is unknown or pending,
    // stop the process on failure or success
    private func startPreAuthPollTimer(for project: Project, _ preAuthResult: PayonePreAuthResult) {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.getPreAuthStatus(for: project, preAuthResult.links.preAuthStatus) { result in
                switch result {
                case .failure(let error):
                    print(error)
                    self?.startPreAuthPollTimer(for: project, preAuthResult)
                case .success(let status):
                    switch status.status {
                    case .unknown, .pending:
                        self?.startPreAuthPollTimer(for: project, preAuthResult)
                    case .successful, .failed:
                        self?.finishPreAuth(with: status.status)
                    }
                }
            }
        }
    }

    // preAuth is finished, either with a failure or successfully.
    private func finishPreAuth(with status: PayonePreAuthStatus) {
        self.pollTimer?.invalidate()

        if status == .failed {
            self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        } else {
            assert(status == .successful)

            guard
                let projectId = self.projectId,
                let project = Snabble.shared.project(for: projectId),
                let cert = Snabble.shared.certificates.first,
                let response = self.payoneResponse,
                let preAuthResult = self.payonePreAuthResult
            else {
                return
            }

            // store the accumulated data in our payment method details
            if let ccData = PayoneCreditCardData(gatewayCert: cert.data,
                                                 response: response,
                                                 preAuthResult: preAuthResult,
                                                 projectId: projectId) {
                let detail = PaymentMethodDetail(ccData)
                PaymentMethodDetails.save(detail)
                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
                goBack()
            } else {
                project.logError("can't create CC data from pay1 response: \(response)")
                showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
            }
        }
    }

    private func showErrorAlert(message: String, goBack: Bool) {
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
            if goBack {
                self.goBack()
            }
        })

        self.present(alert, animated: true)
    }
}

// MARK: - backend endpoints

extension PayoneCreditCardEditViewController {
    // get the info we need for the web form / tokenization request
    private func getPayoneTokenization(for project: Project,
                                       _ link: Link?,
                                       completion: @escaping (Result<PayoneTokenization, SnabbleError>) -> Void ) {
        guard let url = link?.href else {
            Log.error("no tokenization link found")
            return completion(Result.failure(SnabbleError.unknown))
        }

        project.request(.get, url, timeout: 5) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request) { (_ result: Result<PayoneTokenization, SnabbleError>) in
                completion(result)
            }
        }
    }

    // given a newly tokenized card, start the pre auth for e.g. 1€
    private func startPayonePreauthorization(for project: Project,
                                             _ link: Link?,
                                             _ response: PayoneResponse,
                                             completion: @escaping (Result<PayonePreAuthResult, SnabbleError>) -> Void) {
        guard let url = link?.href else {
            Log.error("no preauth link found")
            return completion(Result.failure(SnabbleError.unknown))
        }

        project.request(.post, url, timeout: 5) { request in
            guard var request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            let preAuthData = PayonePreAuthData(pseudoCardPAN: response.pseudoCardPAN, lastname: response.lastname)
            // swiftlint:disable:next force_try
            request.httpBody = try! JSONEncoder().encode(preAuthData)

            project.perform(request) { (_ result: Result<PayonePreAuthResult, SnabbleError>) in
                completion(result)
            }
        }
    }

    // get the status of a pre auth - we need to poll this until status is either `.successful` or `.failed`
    private func getPreAuthStatus(for project: Project,
                                  _ link: Link,
                                  completion: @escaping (Result<PayonePreAuthStatusResult, SnabbleError>) -> Void) {
        project.request(.get, link.href, timeout: 2) { request in
            guard var request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            project.perform(request) { (_ result: Result<PayonePreAuthStatusResult, SnabbleError>) in
                completion(result)
            }
        }
    }
}

// MARK: - web view content

extension PayoneCreditCardEditViewController {
    private func prepareAndInjectPage(_ payoneTokenization: PayoneTokenization) {
        var languageCode = Locale.current.languageCode ?? "en"
        switch languageCode {
        case "de", "en", "fr", "it", "es", "pt", "nl": () // payone supported language
        default: languageCode = "en"
        }

        let testing = payoneTokenization.isTesting ?? false

        let fieldColors = self.traitCollection.userInterfaceStyle == .light ?
            "color: #000; background-color: #fff;" :
            "color: #fff; background-color: #000;"

        let page = PayoneCreditCardEditViewController.pageTemplate
            .replacingOccurrences(of: "{{hash}}", with: payoneTokenization.hash)
            .replacingOccurrences(of: "{{merchantID}}", with: payoneTokenization.merchantID)
            .replacingOccurrences(of: "{{portalID}}", with: payoneTokenization.portalID)
            .replacingOccurrences(of: "{{accountID}}", with: payoneTokenization.accountID)
            .replacingOccurrences(of: "{{mode}}", with: testing ? "test" : "live")
            .replacingOccurrences(of: "{{header}}", with: threeDSecureHint(for: projectId, tokenization: payoneTokenization))
            .replacingOccurrences(of: "{{handler}}", with: Self.handlerName)
            .replacingOccurrences(of: "{{language}}", with: languageCode)
            .replacingOccurrences(of: "{{supportedCardType}}", with: self.brand?.paymentMethod ?? "")
            .replacingOccurrences(of: "{{fieldColors}}", with: fieldColors)
            // TODO: l10n
            .replacingOccurrences(of: "{{lastName}}", with: L10n.Snabble.Payone.lastname)
            .replacingOccurrences(of: "{{cardNumberLabel}}", with: L10n.Snabble.Payone.cardNumber)
            .replacingOccurrences(of: "{{cvcLabel}}", with: L10n.Snabble.Payone.cvc)
            .replacingOccurrences(of: "{{expireMonthLabel}}", with: L10n.Snabble.Payone.expireMonth)
            .replacingOccurrences(of: "{{expireYearLabel}}", with: L10n.Snabble.Payone.expireYear)
            .replacingOccurrences(of: "{{saveButtonLabel}}", with: L10n.Snabble.save)
            .replacingOccurrences(of: "{{incompleteForm}}", with: L10n.Snabble.Payone.incompleteForm)

        // passing a dummy base URL is necessary for the Payone JS to work  ¯\_(ツ)_/¯
        self.webView?.loadHTMLString(page, baseURL: URL(string: "http://127.0.0.1/")!)
    }

    fileprivate static let pageTemplate: String = { () -> String in
        guard
            let path = SnabbleSDKBundle.main.path(forResource: "payone-form", ofType: "html"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else {
            return ""
        }

        return String(bytes: data, encoding: .utf8) ?? ""
    }()
}

// MARK: - webview navigation delegate
extension PayoneCreditCardEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let preAuthResult = self.payonePreAuthResult, let url = navigationAction.request.url?.absoluteString {
            if url == preAuthResult.links.redirectSuccess.href {
                // sca succeeded, we still need to wait for the preAuth status to switch to "success"
                self.activityIndicator?.startAnimating()
                webView.loadHTMLString("", baseURL: nil)
            } else if url == preAuthResult.links.redirectError.href {
                self.finishPreAuth(with: .failed)
            } else if url == preAuthResult.links.redirectBack.href {
                // start from scratch
                self.startCreditCardTokenization()
            }
        }

        decisionHandler(.allow)
    }
}

// MARK: - web view message handler
extension PayoneCreditCardEditViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == Self.handlerName,
            let body = message.body as? [String: Any]
        else {
            return self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        }

        if let log = body["log"] as? String {
            return NSLog("console.log: \(log)")
        } else if let error = body["error"] as? String {
            return showErrorAlert(message: error, goBack: false)
        } else if let response = body["response"] as? [String: Any] {
            let lastName = body["lastName"] as? String
            self.processResponse(response, lastName)
        }
    }
}
