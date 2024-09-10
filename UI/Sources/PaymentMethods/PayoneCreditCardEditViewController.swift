//
//  PayoneCreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
@preconcurrency import WebKit
import SnabbleCore
import SnabbleAssetProviding
import SnabbleUser

// sample data for testing:
//
// Visa: 4716 9719 4035 3559, Expiry: any future date, CVV: any 3-digit number
// Mastercard: 5404 1277 2073 9582, Expiry: any future date, CVV: any 3-digit number
// Amex: 3751 4472 6036 141, Expiry: any future date, CVV: any 4-digit number
//
// 3DSecure password for all: 12345
//
// Backend only supports 3-D Secure verification.
// See: https://docs.payone.com/pages/releaseview.action?pageId=6390627
//
// These credit card numbers (PAN) will simulate successful payment transactions
// for cards taking part in 3-D Secure. The processing is again identical for all
// credit card types. A test with a single type is sufficient
//

public protocol PrefillData {
    var lastName: String? { get }
    var street: String? { get }
    var zip: String? { get }
    var city: String? { get }
    var email: String? { get }
    var country: String? { get }
    var state: String? { get }
}

extension SnabbleUser.User: PrefillData {
    public var street: String? { address?.street }
    public var zip: String? { address?.zip }
    public var city: String? { address?.city }
    public var country: String? { address?.country }
    public var state: String? { address?.state }
}

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

    private static let callbackHandler = "callbackHandler"
    private static let prefillHandler = "prefillHandler"

    private let prefillData: PrefillData?
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

    public init(brand: CreditCardBrand?, prefillData: PrefillData?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        self.prefillData = prefillData
        super.init(nibName: nil, bundle: nil)
    }

    init(_ detail: PaymentMethodDetail, prefillData: PrefillData?, _ analyticsDelegate: AnalyticsDelegate?) {
        if case .payoneCreditCard(let data) = detail.methodData {
            self.brand = data.brand
            self.ccNumber = data.displayName
            self.expDate = data.expirationDate
            self.detail = detail
        }
        self.analyticsDelegate = analyticsDelegate
        self.projectId = nil
        self.prefillData = prefillData
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
            self.title = Asset.localizedString(forKey: "Snabble.Payment.creditCard")
        }

        if self.ccNumber != nil {
            self.webViewContainer.isHidden = true
            self.displayContainer.isHidden = false

            self.cardNumber.text = self.ccNumber
            self.expirationDate.text = self.expDate

            self.cardNumberLabel.text = Asset.localizedString(forKey: "Snabble.CC.cardNumber")
            self.expDateLabel.text = Asset.localizedString(forKey: "Snabble.CC.validUntil")
            self.explanation.text = Asset.localizedString(forKey: "Snabble.CC.editingHint")

            let trash: UIImage? = Asset.image(named: "trash")
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
            showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            // we're being popped - stop timer and break the retain cycle
            self.pollTimer?.invalidate()
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.callbackHandler)
        }
    }

    // get the tokenization data and show the data entry form
    private func tokenizeWithPayone(_ project: Project, _ descriptor: PaymentMethodDescriptor) {
        let link = descriptor.links?.tokenization
        self.getPayoneTokenization(for: project, link) { [weak self] result in
            self?.activityIndicator?.stopAnimating()
            switch result {
            case .failure:
                let alert = UIAlertController(title: "Oops", message: Asset.localizedString(forKey: "Snabble.CC.noEntryPossible"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
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

        return Asset.localizedString(forKey: "Snabble.CC.3dsecureHint.retailerWithPrice", arguments: chargeTotal, name)
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        // container for the "display-only" mode
        displayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayContainer)
        NSLayoutConstraint.activate([
            displayContainer.topAnchor.constraint(equalTo: view.topAnchor),
            displayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: displayContainer.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: displayContainer.trailingAnchor)
        ])

        explanation.translatesAutoresizingMaskIntoConstraints = false
        explanation.numberOfLines = 0
        explanation.font = .preferredFont(forTextStyle: .footnote)
        explanation.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(explanation)

        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardNumberLabel.font = .preferredFont(forTextStyle: .body)
        cardNumberLabel.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(cardNumberLabel)

        cardNumber.translatesAutoresizingMaskIntoConstraints = false
        cardNumber.isEnabled = false
        cardNumber.borderStyle = .roundedRect
        cardNumber.font = .preferredFont(forTextStyle: .body)
        cardNumber.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(cardNumber)

        expDateLabel.translatesAutoresizingMaskIntoConstraints = false
        expDateLabel.font = .preferredFont(forTextStyle: .body)
        expDateLabel.adjustsFontForContentSizeCategory = true
        displayContainer.addSubview(expDateLabel)

        expirationDate.translatesAutoresizingMaskIntoConstraints = false
        expirationDate.isEnabled = false
        expirationDate.borderStyle = .roundedRect
        expirationDate.font = .preferredFont(forTextStyle: .body)
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
        NSLayoutConstraint.activate([
            webViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            webViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor)
        ])

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .systemGray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        webViewContainer.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: webViewContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: webViewContainer.centerYAnchor),

            activityIndicator.topAnchor.constraint(greaterThanOrEqualTo: webViewContainer.topAnchor),
            activityIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: webViewContainer.leadingAnchor),
            webViewContainer.bottomAnchor.constraint(greaterThanOrEqualTo: activityIndicator.bottomAnchor),
            webViewContainer.trailingAnchor.constraint(greaterThanOrEqualTo: activityIndicator.trailingAnchor)
        ])
        self.activityIndicator = activityIndicator

        setupWebView(in: webViewContainer)
    }

    private func setupWebView(in containerView: UIView) {
        let contentController = WKUserContentController()
        contentController.add(self, name: Self.callbackHandler)
        contentController.add(self, name: Self.prefillHandler)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])

        self.webView = webView
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

    // handle the response data we get from the payone web form. if the response is OK, start the pre-auth process
    private func processResponse(_ response: [String: Any], info: PayonePreAuthData?) {
        guard
            let projectId = self.projectId,
            let project = Snabble.shared.project(for: projectId),
            let info = info,
            let response = PayoneResponse(response: response, info: info)
        else {
            return
        }

        startPayonePreauthorization(for: project, payoneTokenization?.links.preAuth, response) { result in
            switch result {
            case .failure(let error):
                print(error)
                self.showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
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
            self.showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
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
            self.showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
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
                showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
            }
        }
    }

    private func showErrorAlert(message: String, goBack: Bool) {
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
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

            // swiftlint:disable:next force_try
            request.httpBody = try! JSONEncoder().encode(response.info)

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
        var languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "de", "en", "fr", "it", "es", "pt", "nl": () // payone supported language
        default: languageCode = "en"
        }
        
        var region: String
        if #available(iOS 16, *) {
            region = Locale.current.region?.identifier ?? "DE"
        } else {
            // Fallback on earlier versions
            region = Locale.current.regionCode ?? "DE"
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
            .replacingOccurrences(of: "{{callbackHandler}}", with: Self.callbackHandler)
            .replacingOccurrences(of: "{{prefillHandler}}", with: Self.prefillHandler)
            .replacingOccurrences(of: "{{language}}", with: languageCode)
            .replacingOccurrences(of: "{{supportedCardType}}", with: self.brand?.paymentMethod ?? "")
            .replacingOccurrences(of: "{{fieldColors}}", with: fieldColors)
            // TODO: l10n
            .replacingOccurrences(of: "{{lastname}}", with: Asset.localizedString(forKey: "Snabble.Payone.lastname"))
            .replacingOccurrences(of: "{{cardNumberLabel}}", with: Asset.localizedString(forKey: "Snabble.Payone.cardNumber"))
            .replacingOccurrences(of: "{{cvcLabel}}", with: Asset.localizedString(forKey: "Snabble.Payone.cvc"))
            .replacingOccurrences(of: "{{expireMonthLabel}}", with: Asset.localizedString(forKey: "Snabble.Payone.expireMonth"))
            .replacingOccurrences(of: "{{expireYearLabel}}", with: Asset.localizedString(forKey: "Snabble.Payone.expireYear"))
            .replacingOccurrences(of: "{{saveButtonLabel}}", with: Asset.localizedString(forKey: "Snabble.save"))
            .replacingOccurrences(of: "{{incompleteForm}}", with: Asset.localizedString(forKey: "Snabble.Payone.incompleteForm"))
            .replacingOccurrences(of: "{{email}}", with: Asset.localizedString(forKey: "Snabble.Payone.email"))
            .replacingOccurrences(of: "{{street}}", with: Asset.localizedString(forKey: "Snabble.Payone.street"))
            .replacingOccurrences(of: "{{zip}}", with: Asset.localizedString(forKey: "Snabble.Payone.zip"))
            .replacingOccurrences(of: "{{city}}", with: Asset.localizedString(forKey: "Snabble.Payone.city"))
            .replacingOccurrences(of: "{{country}}", with: Asset.localizedString(forKey: "Snabble.Payone.country"))
            .replacingOccurrences(of: "{{countryHint}}", with: Asset.localizedString(forKey: "Snabble.Payone.countryHint"))
            .replacingOccurrences(of: "{{state}}", with: Asset.localizedString(forKey: "Snabble.Payone.state"))
            .replacingOccurrences(of: "{{stateHint}}", with: Asset.localizedString(forKey: "Snabble.Payone.stateHint"))
            .replacingOccurrences(of: "{{localeCountryCode}}", with: region)

        // passing a dummy base URL is necessary for the Payone JS to work  ¯\_(ツ)_/¯
        self.webView?.loadHTMLString(page, baseURL: URL(string: "http://127.0.0.1/")!)
    }

    fileprivate static let pageTemplate: String = { () -> String in
        guard
            let path = Bundle.module.path(forResource: "payone-form", ofType: "html"),
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
        if message.name == Self.callbackHandler,
           let body = message.body as? [String: Any] {
            if let log = body["log"] as? String {
                print("console.log: \(log)")
            } else if let error = body["error"] as? String {
                showErrorAlert(message: error, goBack: false)
            } else if let response = body["response"] as? [String: Any] {
                processResponse(response, info: PayonePreAuthData(withPAN: response["pseudocardpan"] as? String, body: body))
            }
        } else if message.name == Self.prefillHandler,
                  let body = message.body as? [String] {
            let jsonString = prefillString(forIdentifiers: body, from: prefillData)
            message.webView?.evaluateJavaScript("prefillForm(\(jsonString))")
        } else {
            return self.showErrorAlert(message: Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error"), goBack: true)
        }
    }

    private func prefillString(forIdentifiers ids: [String], from prefillData: PrefillData?) -> String {
        let data = ids.reduce(into: [String: String]()) {
            switch $1 {
            case "country":
                $0[$1] = prefillData?.country
            case "state":
                $0[$1] = prefillData?.state
            case "email":
                $0[$1] = prefillData?.email
            case "lastname":
                $0[$1] = prefillData?.lastName
            case "street":
                $0[$1] = prefillData?.street
            case "zip":
                $0[$1] = prefillData?.zip
            case "city":
                $0[$1] = prefillData?.city
            default:
                break
            }
        }
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: data,
            options: []) else {
            return "{}"
        }
        return String(decoding: jsonData, as: UTF8.self)
    }
}
