//
//  CreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit

// sample data for testing:
//
// Visa: 4242 4242 4242 4242, Expiry: any future date, CVV: any 3-digit number
// Mastercard: 5555 5555 5555 4444, Expiry: any future date, CVV: any 3-digit number
// Amex: 3714 4963 5398 431, Expiry: any future date, CVV: any 4-digit number
//
// see https://stripe.com/docs/testing

// response object for the `telecashVaultItems` endpoint (POST w/empty body)
private struct TelecashVaultItem: Decodable {
    let chargeTotal: String
    let currency: String
    let date: String
    let hash: String
    let links: TelecashVaultItemLinks
    let orderId: String
    let storeId: String
    let url: String // DELETE this to cancel the pre-auth

    struct TelecashVaultItemLinks: Decodable {
        let `self`: Link
    }
}

public final class CreditCardEditViewController: UIViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    @IBOutlet private weak var cardNumberLabel: UILabel!
    @IBOutlet private weak var cardNumber: UITextField!

    @IBOutlet private weak var expDateLabel: UILabel!
    @IBOutlet private weak var expirationDate: UITextField!

    @IBOutlet private weak var explanation: UILabel!

    private var webView: WKWebView!

    private var detail: PaymentMethodDetail?
    private var brand: CreditCardBrand?
    private var ccNumber: String?
    private var expDate: String?
    private let showFromCart: Bool
    private let projectId: Identifier<Project>?
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var vaultItem: TelecashVaultItem?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        print("cc edit for \(projectId)")

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    init(_ detail: PaymentMethodDetail, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        if case .creditcard(let data) = detail.methodData {
            self.brand = data.brand
            self.ccNumber = data.displayName
            self.expDate = data.expirationDate
            self.detail = detail
        }
        self.showFromCart = showFromCart
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
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch self.brand {
        case .visa: self.title = "VISA"
        case .mastercard: self.title = "Mastercard"
        case .amex: self.title = "American Express"
        case .none: self.title = "Snabble.Payment.CreditCard".localized()
        }

        if self.ccNumber != nil {
            self.containerView.isHidden = true

            self.cardNumber.text = self.ccNumber
            self.expirationDate.text = self.expDate

            self.cardNumberLabel.text = "Snabble.CC.cardNumber".localized()
            self.expDateLabel.text = "Snabble.CC.validUntil".localized()
            self.explanation.text = "Snabble.CC.editingHint".localized()

            let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            self.detail == nil,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId)
        else {
            return
        }

        self.setupWebView()
        self.containerView.bringSubviewToFront(self.spinner)

        self.spinner.startAnimating()
        self.getTelecashVaultItem(for: project) { result in
            self.spinner.stopAnimating()
            switch result {
            case .failure:
                let alert = UIAlertController(title: "Oops", message: "Snabble.CC.noEntryPossible".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
                    self.goBack()
                })
            case .success(let vaultItem):
                self.vaultItem = vaultItem
                self.prepareAndInjectPage(vaultItem)
            }
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            if self.showFromCart {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if self.showFromCart {
                self.navigationDelegate?.goBackToCart()
            } else {
                self.navigationDelegate?.goBack()
            }
        }
    }

    private func prepareAndInjectPage(_ vaultItem: TelecashVaultItem) {
        let page = CreditCardEditViewController.pageTemplate
            .replacingOccurrences(of: "{{url}}", with: vaultItem.url)
            .replacingOccurrences(of: "{{date}}", with: vaultItem.date)
            .replacingOccurrences(of: "{{storeId}}", with: vaultItem.storeId)
            .replacingOccurrences(of: "{{currency}}", with: vaultItem.currency)
            .replacingOccurrences(of: "{{chargeTotal}}", with: vaultItem.chargeTotal)
            .replacingOccurrences(of: "{{hash}}", with: vaultItem.hash)
            .replacingOccurrences(of: "{{paymentMethod}}", with: self.brand?.paymentMethod ?? "V")
            .replacingOccurrences(of: "{{locale}}", with: Locale.current.identifier)
            .replacingOccurrences(of: "{{header}}", with: "Snabble.CC.3dsecureHint".localized())
            .replacingOccurrences(of: "{{hostedDataId}}", with: UUID().uuidString)
            .replacingOccurrences(of: "{{orderId}}", with: vaultItem.orderId)

        self.webView.loadHTMLString(page, baseURL: nil)
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        self.webView = WKWebView(frame: self.containerView.bounds, configuration: config)
        self.webView.navigationDelegate = self

        self.containerView.addSubview(self.webView)
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Snabble.Payment.delete.message".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.brand?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

extension CreditCardEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension CreditCardEditViewController: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == "callbackHandler",
            let body = message.body as? [String: Any],
            let eventData = body["elementArr"] as? [[String: String]],
            let storeId = self.vaultItem?.storeId,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
            let cert = SnabbleAPI.certificates.first
        else {
            return self.showError()
        }

        let connectResponse = ConnectGatewayResponse(response: eventData)

        if let ccData = CreditCardData(connectResponse, projectId, storeId, certificate: cert.data) {
            let detail = PaymentMethodDetail(ccData)
            PaymentMethodDetails.save(detail)
            self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
            self.deletePreauth(project, self.vaultItem?.links.`self`.href)
        } else if connectResponse.failCode == "5993" {
            NSLog("cancelled by user")
        } else {
            NSLog("unknown error response_code=\(connectResponse.responseCode) fail_rc=\(connectResponse.failCode) fail_reason=\(connectResponse.failReason)")
            return self.showError()
        }

        self.goBack()
    }

    private func showError() {
        let alert = UIAlertController(title: "Snabble.Payment.CreditCard.error".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }
}

extension CreditCardEditViewController {

    private func getTelecashVaultItem(for project: Project, completion: @escaping (Result<TelecashVaultItem, SnabbleError>) -> Void ) {
        guard let url = project.links.telecashVaultItems?.href else {
            Log.error("no telecashVaultItems in metadata")
            return completion(Result.failure(SnabbleError.unknown))
        }

        project.request(.post, url, timeout: 5) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request) { (_ result: Result<TelecashVaultItem, SnabbleError>) in
                completion(result)
            }
        }
    }

    private func deletePreauth(_ project: Project, _ url: String?) {
        guard let url = url else {
            return
        }

        project.request(.delete, url, timeout: 5) { request in
            guard let request = request else {
                return
            }

            struct DeleteResponse: Decodable {}
            project.perform(request) { (_ result: Result<DeleteResponse, SnabbleError>) in
                print(result)
            }
        }
    }
}

// stuff that's only used by the RN wrapper
extension CreditCardEditViewController: ReactNativeWrapper {
    public func setBrand(_ brand: CreditCardBrand) {
        self.brand = brand
    }

    public func setDetail(_ detail: PaymentMethodDetail) {
        guard case .creditcard(let data) = detail.methodData else {
            return
        }

        self.detail = detail
        self.brand = data.brand
        self.ccNumber = data.displayName
        self.expDate = data.expirationDate
    }
}

extension CreditCardEditViewController {
    fileprivate static let pageTemplate = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style type='text/css'>
                * { font-family: -apple-system,sans-serif; font-size: 17px }
                @media (prefers-color-scheme: dark) {
                    * { background-color: #000; color: #fff; }
                }
                .header { margin: 10px 8px; }
            </style>
        </head>
        <body>
            <div class="header">{{header}}</div>
            <iframe name="embed1" id="embed1" src="#" width="100%" height="900px" style="border: none;">
            </iframe>

            <form method="post" action="{{url}}" target="embed1" id="form1">
                <input type="hidden" name="txntype" value="preauth">
                <input type="hidden" name="timezone" value="UTC"/>
                <input type="hidden" name="txndatetime" value="{{date}}"/>
                <input type="hidden" name="hash_algorithm" value="SHA256"/>
                <input type="hidden" name="hash" value="{{hash}}"/>
                <input type="hidden" name="storename" value="{{storeId}}"/>
                <input type="hidden" name="currency" value="{{currency}}"/>
                <input type="hidden" name="chargetotal" value="{{chargeTotal}}" />
                <input type="hidden" name="paymentMethod" value="{{paymentMethod}}" />
                <input type="hidden" name="mode" value="payonly"/>
                <input type="hidden" name="responseFailURL" value="about:blank"/>
                <input type="hidden" name="responseSuccessURL" value="about:blank"/>
                <input type="hidden" name="checkoutoption" value="simpleform"/>
                <input type="hidden" name="assignToken" value="false"/>
                <input type="hidden" name="hostURI" value="*"/>
                <input type="hidden" name="language" value="{{locale}}"/>
                <input type="hidden" name="authenticateTransaction" value="true"/>
                <input type="hidden" name="threeDSRequestorChallengeIndicator" value="04"/>
                <input type="hidden" name="hosteddataid" value="{{hostedDataId}}"/>
                <input type="hidden" name="oid" value="{{orderId}}"/>
            </form>
            <script>
            window.addEventListener("message", function receiveMessage(event) {
                try {
                    webkit.messageHandlers.callbackHandler.postMessage(event.data);
                } catch (err) {
                    console.log('The native context does not exist yet');
                }
            });
            document.getElementById('form1').submit()
            </script>
        </body>
        </html>
        """
}
