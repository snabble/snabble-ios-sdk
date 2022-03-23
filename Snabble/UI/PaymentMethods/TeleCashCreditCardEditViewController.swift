//
//  TeleCashCreditCardEditViewController.swift
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

public final class TeleCashCreditCardEditViewController: UIViewController {
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
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var vaultItem: TelecashVaultItem?

    public init(brand: CreditCardBrand?, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId

        super.init(nibName: nil, bundle: SnabbleBundle.main)
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

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

            let trash = Asset.SnabbleSDK.iconTrash.image
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            self.detail == nil,
            let brand = self.brand,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == brand.method })
        else {
            return
        }

        self.setupWebView()
        self.containerView.bringSubviewToFront(self.spinner)

        self.spinner.startAnimating()

        if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
            tokenizeWithTelecash(project, descriptor)
        } else {
            // oops - somehow we got here for a non-IPG tokenization. Bail out.
            showError()
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // required to break the retain cycle
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
    }

    private func tokenizeWithTelecash(_ project: Project, _ descriptor: PaymentMethodDescriptor) {
        let link = descriptor.links?.tokenization
        self.getTelecashVaultItem(for: project, link) { [weak self] result in
            self?.spinner.stopAnimating()
            switch result {
            case .failure:
                let alert = UIAlertController(title: "Oops", message: L10n.Snabble.Cc.noEntryPossible, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
                    self?.goBack()
                })
                self?.present(alert, animated: true)
            case .success(let vaultItem):
                self?.vaultItem = vaultItem
                self?.prepareAndInjectPage(vaultItem)
            }
        }
    }

    private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    private func prepareAndInjectPage(_ vaultItem: TelecashVaultItem) {
        let page = TeleCashCreditCardEditViewController.pageTemplate
            .replacingOccurrences(of: "{{url}}", with: vaultItem.url)
            .replacingOccurrences(of: "{{date}}", with: vaultItem.date)
            .replacingOccurrences(of: "{{storeId}}", with: vaultItem.storeId)
            .replacingOccurrences(of: "{{currency}}", with: vaultItem.currency)
            .replacingOccurrences(of: "{{chargeTotal}}", with: vaultItem.chargeTotal)
            .replacingOccurrences(of: "{{hash}}", with: vaultItem.hash)
            .replacingOccurrences(of: "{{paymentMethod}}", with: self.brand?.paymentMethod ?? "V")
            .replacingOccurrences(of: "{{locale}}", with: Locale.current.identifier)
            .replacingOccurrences(of: "{{header}}", with: threeDSecureHint(for: projectId, vaultItem))
            .replacingOccurrences(of: "{{hostedDataId}}", with: UUID().uuidString)
            .replacingOccurrences(of: "{{orderId}}", with: vaultItem.orderId)

        self.webView?.loadHTMLString(page, baseURL: nil)
    }

    private func threeDSecureHint(for projectId: Identifier<Project>?, _ vaultItem: TelecashVaultItem) -> String {
        var name = "snabble"
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.numberStyle = .currency

        if let projectId = self.projectId, let project = SnabbleAPI.project(for: projectId) {
            name = project.company?.name ?? project.name
            fmt.minimumFractionDigits = project.decimalDigits
            fmt.maximumFractionDigits = project.decimalDigits
            fmt.currencyCode = project.currency
            fmt.currencySymbol = project.currencySymbol
            fmt.locale = Locale(identifier: project.locale)
        }

        let chargeDecimal = Decimal(string: vaultItem.chargeTotal.replacingOccurrences(of: ",", with: "."))
        let chargeTotal = fmt.string(for: chargeDecimal)!

        return L10n.Snabble.Cc._3dsecureHint.retailerWithPrice(chargeTotal, name)
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: Self.handlerName)

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
        guard
            message.name == Self.handlerName,
            let body = message.body as? [String: Any],
            let eventData = body["elementArr"] as? [[String: String]],
            let storeId = self.vaultItem?.storeId,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
            let cert = SnabbleAPI.certificates.first
        else {
            return self.showError()
        }

        do {
            let connectResponse = try ConnectGatewayResponse(response: eventData)
            if let ccData = TeleCashCreditCardData(connectResponse, projectId, storeId, certificate: cert.data) {
                let detail = PaymentMethodDetail(ccData)
                PaymentMethodDetails.save(detail)
                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
                self.deletePreauth(project, self.vaultItem?.links._self.href)
                goBack()
            } else {
                project.logError("can't create CC data from IPG response: \(connectResponse)")
                showError()
            }
        } catch ConnectGatewayResponse.Error.gateway(let reason, let code) {
            switch code {
            case "5993":
                // user tapped "cancel"
                goBack()
            default:
                let msg = "IPG error: fail_rc=\(code) fail_reason=\(reason)"
                project.logError(msg)
                showError()
            }
        } catch {
            let msg = "error parsing IPG response: \(error) eventData=\(eventData)"
            project.logError(msg)
            showError()
        }
    }

    private func showError() {
        let alert = UIAlertController(title: L10n.Snabble.Payment.CreditCard.error, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }
}

extension TeleCashCreditCardEditViewController {
    private func getTelecashVaultItem(for project: Project,
                                      _ link: Link?,
                                      completion: @escaping (Result<TelecashVaultItem, SnabbleError>) -> Void ) {
        guard let url = link?.href else {
            Log.error("no telecashVaultItems tokenization link found")
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

extension TeleCashCreditCardEditViewController {
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
                <input type="hidden" name="unscheduledCredentialOnFileType" value="FIRST"/>
                <input type="hidden" name="hosteddataid" value="{{hostedDataId}}"/>
                <input type="hidden" name="oid" value="{{orderId}}"/>
            </form>
            <script>
            window.addEventListener("message", function receiveMessage(event) {
                try {
                    webkit.messageHandlers.\(handlerName).postMessage(event.data);
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
