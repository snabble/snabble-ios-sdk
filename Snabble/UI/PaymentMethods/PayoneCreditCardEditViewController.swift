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
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    @IBOutlet private var cardNumberLabel: UILabel!
    @IBOutlet private var cardNumber: UITextField!

    @IBOutlet private var expDateLabel: UILabel!
    @IBOutlet private var expirationDate: UITextField!

    @IBOutlet private var explanation: UILabel!

    private var webView: WKWebView!
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

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId

        super.init(nibName: nil, bundle: SnabbleBundle.main)
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

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }

        self.setupWebView()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let brand = self.brand {
            self.title = brand.displayName
        } else {
            self.title = L10n.Snabble.Payment.creditCard
        }

        if self.ccNumber != nil {
            self.containerView.isHidden = true

            self.cardNumber.text = self.ccNumber
            self.expirationDate.text = self.expDate

            self.cardNumberLabel.text = L10n.Snabble.Cc.cardNumber
            self.expDateLabel.text = L10n.Snabble.Cc.validUntil
            self.explanation.text = L10n.Snabble.Cc.editingHint

            let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.payoneTokenization == nil {
            self.startCreditCardTokenization()
        }
    }

    private func startCreditCardTokenization() {
        guard
            self.detail == nil,
            let brand = self.brand,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == brand.method })
        else {
            return
        }

        self.payoneTokenization = nil
        self.payonePreAuthResult = nil
        self.payoneResponse = nil
        self.pollTimer?.invalidate()

        self.containerView.bringSubviewToFront(self.spinner)

        self.spinner.startAnimating()

        if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
             tokenizeWithPayone(project, descriptor)
        } else {
            // oops - somehow we got here for a non-payone tokenization. Bail out.
            showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            // we're being popped
            self.pollTimer?.invalidate()
            // required to break the retain cycle
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        }
    }

    private func tokenizeWithPayone(_ project: Project, _ descriptor: PaymentMethodDescriptor) {
        let link = descriptor.links?.tokenization
        self.getPayoneTokenization(for: project, link) { [weak self] result in
            self?.spinner.stopAnimating()
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
        if SnabbleUI.implicitNavigation {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.navigationDelegate?.goBack()
        }
    }

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

    private func threeDSecureHint(for projectId: Identifier<Project>?, tokenization: PayoneTokenization) -> String {
        var name = "snabble"
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.numberStyle = .currency
        fmt.currencyCode = tokenization.preAuthInfo.currency

        var amount = Decimal(tokenization.preAuthInfo.amount)
        if let projectId = self.projectId, let project = SnabbleAPI.project(for: projectId) {
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

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: Self.handlerName)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(self.webView)

        NSLayoutConstraint.activate(webView.constraintsForAnchoringTo(boundsOf: containerView))
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
}

// MARK: - webview delegate & msg handler
extension PayoneCreditCardEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let preAuthResult = self.payonePreAuthResult, let url = navigationAction.request.url?.absoluteString {
            if url == preAuthResult.links.redirectSuccess.href {
                // sca succeeded, we still need to wait for the preAuth status to switch to "success"
                self.spinner.startAnimating()
                self.webView.loadHTMLString("", baseURL: nil)
            } else if url == preAuthResult.links.redirectError.href {
                self.finishPreAuth(with: .failed)
            } else if url == preAuthResult.links.redirectBack.href {
                self.startCreditCardTokenization()
            }
        }

        decisionHandler(.allow)
    }
}

extension PayoneCreditCardEditViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == Self.handlerName,
            let body = message.body as? [String: Any]
        else {
            return self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        }

        if let log = body["log"] as? String {
            return NSLog("P1 console.log \(log)")
        } else if let error = body["error"] as? String {
            return showErrorAlert(message: error, goBack: false)
        } else if let response = body["response"] as? [String: Any] {
            print("yay! valid response!")
            let lastName = body["lastName"] as? String
            self.processResponse(response, lastName)
        }
    }

    private func processResponse(_ response: [String: Any], _ lastname: String?) {
        guard
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
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

    private func loadScaChallenge(for project: Project, _ preAuthResult: PayonePreAuthResult, _ response: PayoneResponse) {
        guard
            let url = URL(string: preAuthResult.links.scaChallenge.href)
        else {
            self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
            return
        }

        let scaRequest = URLRequest(url: url)
        self.webView.load(scaRequest)

        self.payonePreAuthResult = preAuthResult
        self.payoneResponse = response

        self.startPreAuthPollTimer(for: project, preAuthResult)
    }

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

    private func finishPreAuth(with status: PayonePreAuthStatus) {
        self.pollTimer?.invalidate()

        print("finished! status=\(status)")

        if status == .failed {
            self.showErrorAlert(message: L10n.Snabble.Payment.CreditCard.error, goBack: true)
        } else {
            assert(status == .successful)

            guard
                let projectId = self.projectId,
                let project = SnabbleAPI.project(for: projectId),
                let cert = SnabbleAPI.certificates.first,
                let response = self.payoneResponse,
                let preAuthResult = self.payonePreAuthResult
            else {
                return
            }

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

    private func startPayonePreauthorization(for project: Project, _ link: Link?, _ response: PayoneResponse,
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

    private func getPreAuthStatus(for project: Project, _ link: Link, completion: @escaping (Result<PayonePreAuthStatusResult, SnabbleError>) -> Void) {
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

// stuff that's only used by the RN wrapper
extension PayoneCreditCardEditViewController: ReactNativeWrapper {
    public func setBrand(_ brand: CreditCardBrand) {
        self.brand = brand
    }

    public func setProjectId(_ projectId: String) {
        self.projectId = Identifier<Project>(rawValue: projectId)
    }

    public func setDetail(_ detail: PaymentMethodDetail) {
        guard case .payoneCreditCard(let data) = detail.methodData else {
            return
        }

        self.detail = detail
        self.brand = data.brand
        self.ccNumber = data.displayName
        self.expDate = data.expirationDate
    }
}

extension PayoneCreditCardEditViewController {
    fileprivate static let pageTemplate: String = { () -> String in
        guard
            let path = SnabbleBundle.main.path(forResource: "payone-form", ofType: "html"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else {
            return ""
        }

        return String(bytes: data, encoding: .utf8) ?? ""
    }()
}
