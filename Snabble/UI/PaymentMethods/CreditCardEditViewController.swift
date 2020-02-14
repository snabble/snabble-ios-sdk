//
//  CreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit

// sample data for testing:
// Visa: 4921 8180 8989 8988, Exp. 12/2020, CVV: any 3-digit number
// MasterCard: 5404 1070 0002 0010, Exp. 12/2020, CVV: any 3-digit number

public final class CreditCardEditViewController: UIViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    @IBOutlet private weak var cardNumberLabel: UILabel!
    @IBOutlet private weak var cardNumber: UITextField!

    @IBOutlet private weak var expDateLabel: UILabel!
    @IBOutlet private weak var expirationDate: UITextField!

    @IBOutlet private weak var explanation: UILabel!

    private var webView: WKWebView!
    private let brand: CreditCardBrand
    private var index: Int?
    private var ccNumber: String?
    private var expDate: String?
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var telecash: TelecashSecret?

    public init(_ brand: CreditCardBrand, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = brand
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    init(_ creditcardData: CreditCardData, _ index: Int, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brand = creditcardData.brand
        self.index = index
        self.ccNumber = creditcardData.displayName
        self.expDate = creditcardData.expirationDate
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        switch self.brand {
        case .visa: self.title = "VISA"
        case .mastercard: self.title = "Mastercard"
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

        guard self.index == nil else {
            return
        }

        self.setupWebView()
        self.containerView.bringSubviewToFront(self.spinner)

        self.spinner.startAnimating()
        SnabbleAPI.getTelecashSecret(SnabbleAPI.projects[0]) { result in
            self.spinner.stopAnimating()
            switch result {
            case .failure:
                let alert = UIAlertController(title: "Oops", message: "Snabble.CC.noEntryPossible".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
            case .success(let telecash):
                self.telecash = telecash
                self.prepareAndInjectPage(telecash)
            }
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    private func prepareAndInjectPage(_ telecash: TelecashSecret) {
        let page = CreditCardEditViewController.pageTemplate
            .replacingOccurrences(of: "{{url}}", with: telecash.url)
            .replacingOccurrences(of: "{{date}}", with: telecash.date)
            .replacingOccurrences(of: "{{storeId}}", with: telecash.storeId)
            .replacingOccurrences(of: "{{currency}}", with: telecash.currency)
            .replacingOccurrences(of: "{{chargeTotal}}", with: telecash.chargeTotal)
            .replacingOccurrences(of: "{{hash}}", with: telecash.hash)
            .replacingOccurrences(of: "{{paymentMethod}}", with: self.brand.paymentMethod)
            .replacingOccurrences(of: "{{locale}}", with: Locale.current.identifier)
            .replacingOccurrences(of: "{{header}}", with: "Snabble.CC.3dsecureHint".localized())

        self.webView.loadHTMLString(page, baseURL: nil)
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        self.webView = WKWebView(frame: self.containerView.bounds, configuration: config)

        self.containerView.addSubview(self.webView)
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let index = self.index else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Snabble.Payment.delete.message".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            PaymentMethodDetails.remove(at: index)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.brand.rawValue))
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

extension CreditCardEditViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == "callbackHandler",
            let body = message.body as? [String: Any],
            let eventData = body["elementArr"] as? [[String: String]],
            let storeId = self.telecash?.storeId
        else {
            return
        }

        var hostedDataId = ""
        var cardNumber = ""
        var cardHolder = ""
        var brand = ""
        var expMonth = ""
        var expYear = ""
        var responseCode = ""
        var failReason = ""
        var failCode = ""
        var orderId = ""

        for entry in eventData {
            guard let name = entry["name"], let value = entry["value"] else {
                continue
            }

            switch name {
            case "hosteddataid": hostedDataId = value
            case "cardnumber": cardNumber = value
            case "bname": cardHolder = value
            case "ccbrand": brand = value
            case "expmonth": expMonth = value
            case "expyear": expYear = value
            case "processor_response_code": responseCode = value
            case "fail_reason": failReason = value
            case "fail_rc": failCode = value
            case "oid": orderId = value
            default: ()
            }
        }

        let cert = SnabbleAPI.certificates.first
        if responseCode == "00", let ccData = CreditCardData(cert?.data, cardHolder, cardNumber, brand, expMonth, expYear, hostedDataId, storeId) {
            let detail = PaymentMethodDetail(ccData)
            PaymentMethodDetails.save(detail)
            self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
            NotificationCenter.default.post(name: .paymentMethodsChanged, object: self)
            SnabbleAPI.deletePreauth(SnabbleUI.project, orderId)
        }
        else if failCode == "5993" {
            NSLog("cancelled by user")
        }
        else {
            NSLog("unknown error \(failCode) \(failReason)")
        }

        self.navigationController?.popToInstanceOf(PaymentMethodListViewController.self, animated: true)
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
                <input type="hidden" name="assignToken" value="true"/>
                <input type="hidden" name="hostURI" value="*"/>
                <input type="hidden" name="language" value="{{locale}}"/>
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
