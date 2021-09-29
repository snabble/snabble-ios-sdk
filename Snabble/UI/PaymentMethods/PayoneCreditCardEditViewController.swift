//
//  PayoneCreditCardEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit

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
//

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
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var payoneTokenization: PayoneTokenization?

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

        if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
            tokenizeWithPayone(project, descriptor)
        } else {
            // oops - somehow we got here for a non-payone tokenization. Bail out.
            showError()
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // required to break the retain cycle
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
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
        let testing = payoneTokenization.isTesting ?? false
        let page = PayoneCreditCardEditViewController.pageTemplate
            .replacingOccurrences(of: "{{hash}}", with: payoneTokenization.hash)
            .replacingOccurrences(of: "{{merchantID}}", with: payoneTokenization.merchantID)
            .replacingOccurrences(of: "{{portalID}}", with: payoneTokenization.portalID)
            .replacingOccurrences(of: "{{accountID}}", with: payoneTokenization.accountID)
            .replacingOccurrences(of: "{{mode}}", with: testing ? "test" : "live")
            .replacingOccurrences(of: "{{header}}", with: threeDSecureHint(for: projectId))

        self.webView?.loadHTMLString(page, baseURL: nil)
    }

    private func threeDSecureHint(for projectId: Identifier<Project>?) -> String {
        var name = "snabble"

        if let projectId = self.projectId, let project = SnabbleAPI.project(for: projectId) {
            name = project.company?.name ?? project.name
        }

        #warning("FIXME - is this text still correct?")
        return L10n.Snabble.Cc._3dsecureHint.retailer(name)
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

extension PayoneCreditCardEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension PayoneCreditCardEditViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == Self.handlerName,
            let projectId = self.projectId,
            let project = SnabbleAPI.project(for: projectId),
            let cert = SnabbleAPI.certificates.first
        else {
            return self.showError()
        }

        print(message.body)
//        do {
//            let response = try PayoneResponse(response: eventData)
//            if let ccData = PayoneCreditCardData(gatewayCert: cert.data, response: response, projectId: projectId) {
//                let detail = PaymentMethodDetail(ccData)
//                PaymentMethodDetails.save(detail)
//                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))
//                goBack()
//            } else {
//                project.logError("can't create CC data from pay1 response: \(response)")
//                showError()
//            }
//        } catch ConnectGatewayResponse.Error.gateway(let reason, let code) {
//            switch code {
//            case "5993":
//                // user tapped "cancel"
//                goBack()
//            default:
//                let msg = "pay1 error: fail_rc=\(code) fail_reason=\(reason)"
//                project.logError(msg)
//                showError()
//            }
//        } catch {
//            let msg = "error parsing pay1 response: \(error) eventData=\(eventData)"
//            project.logError(msg)
//            showError()
//        }
    }

    private func showError() {
        let alert = UIAlertController(title: L10n.Snabble.Payment.CreditCard.error, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }
}

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
    // based on https://docs.payone.com/display/public/PLATFORM/Cardtype+set+by+shop-system
    fileprivate static let pageTemplate = """
        <html>
        <head lang="de">
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <script type="text/javascript">
                // intercept errors
                window.onerror = (msg, url, line, column, error) => {
                  const message = {
                    message: msg,
                    url: url,
                    line: line,
                    column: column,
                    error: JSON.stringify(error)
                  }

                  window.webkit.messageHandlers.\(handlerName).postMessage(message);
                };

                // intercept console.log and console.debug
                var console = {
                    log: function(msg) { window.webkit.messageHandlers.\(handlerName).postMessage(msg) }
                    debug: function(msg) { window.webkit.messageHandlers.\(handlerName).postMessage(msg) }
                };
            </script>
            <style type="text/css" media="screen">
                * {
                    margin: 0;
                    padding: 0;
                }
                body {
                    background: #fff;
                    color: #000;
                    font-size: 17px;
                    font-family: -apple-system, sans-serif;
                }
                @media (prefers-color-scheme: dark) {
                  body {
                    background-color: #000;
                    color: #fff; }
                }
                fieldset {
                    border: none;
                    padding: 16px;
                }
                label {
                    display: block;
                    float: left;
                    text-align: right;
                    margin-right: 12px;
                    width: 110px;
                    height: 33px;
                }
                input, select {
                    font-size: 100%; height: 33px;
                }
                select {
                    margin-right: 10px;
                }
                input, .inputIframe, select {
                    margin-bottom: 16px;
                }

                input {
                    width: 160px; font-size: 100%;
                }

                #paymentsubmit {
                    width: 100%;
                }
                #errorOutput {
                    text-align: center;
                    color: #ff0000;
                    display: block;
                }
                #appWrapper {
                  max-width: 400px;
                  margin: auto;
                }
            </style>
        </head>
        <body>
        <script type="text/javascript" src="https://secure.pay1.de/client-api/js/v1/payone_hosted_min.js"></script>
        <form name="paymentform" action="" method="post">
            <fieldset>
                <div id="appWrapper">
                  <input type="hidden" name="pseudocardpan" id="pseudocardpan">
                  <input type="hidden" name="truncatedcardpan" id="truncatedcardpan">

                  <!-- configure your cardtype-selection here -->
                  <div class="row">
                    <label for="cardtypeInput">Karte</label>
                    <select id="cardtype">
                        <option value="V">VISA</option>
                        <option value="M">Mastercard</option>
                        <option value="A">Amex</option>
                    </select>
                  </div>

                  <div class="row">
                    <label for="cardpanInput">Kartennummer</label> <!-- TODO: l10n -->
                    <span class="inputIframe" id="cardpan"></span>
                  </div>

                  <div class="row">
                    <label for="cvcInput">Prüfnummer</label> <!-- TODO: l10n -->
                    <span id="cardcvc2" class="inputIframe"></span>
                  </div>

                  <div class="row">
                    <label for="expireInput">Ablaufdatum</label> <!-- TODO: l10n -->
                    <span id="expireInput" class="inputIframe">
                        <span id="cardexpiremonth"></span>
                        <span id="cardexpireyear"></span>
                    </span>
                  </div>

                  <div class="row">
                    <label for="firstname">Vorname</label> <!-- TODO: l10n -->
                    <input id="firstname" type="text" name="firstname" value="">
                  </div>

                  <div class="row">
                    <label for="lastname">Nachname</label> <!-- TODO: l10n -->
                    <input id="lastname" type="text" name="lastname" value="">
                  </div>

                  <div class="row">
                    <div id="errorOutput"></div>
                  </div>
                </div>

                <input id="paymentsubmit" type="button" value="Speichern" onclick="check();"> <!-- TODO: l10n -->
            </fieldset>
        </form>

        <div id="paymentform"></div>
        <script>
            var request, config;
        foo + - / %
            config = {
                fields: {
                    cardpan: {
                        selector: "cardpan",                 // put name of your div-container here
                        type: "text"                         // text (default), password, tel
                    },
                    cardcvc2: {
                        selector: "cardcvc2",                // put name of your div-container here
                        type: "password",                    // select(default), text, password, tel
                        size: "4",
                        maxlength: "4",                      // set max. length for CVC input; empty values possible
                        length: { "A": 4, "V": 3, "M": 3, "J": 0 } // set required CVC length per cardtype
                                                             // if set exact length required; 0=CVC input disabled
                    },
                    cardexpiremonth: {
                        selector: "cardexpiremonth",         // put name of your div-container here
                        type: "select",                      // select(default), text, password, tel
                        size: "2",
                        maxlength: "2",
                        iframe: {
                            width: "50px"
                        }
                    },
                    cardexpireyear: {
                        selector: "cardexpireyear",          // put name of your div-container here
                        type: "select",                      // select(default), text, password, tel
                        iframe: {
                            width: "80px"
                        }
                    }
                },
                defaultStyle: {
                    input: "font-size: 100%",
                    iframe: {
                        height: "33px",
                        width: "160px",
                    }
                },
                error: "errorOutput",                        // area to display error-messages (optional)
                language: Payone.ClientApi.Language.de       // Language to display error-messages
                                                             // (default: Payone.ClientApi.Language.en)
                                                             // TODO: l10n
            };

            request = {
                request: 'creditcardcheck',                  // fixed value
                responsetype: 'JSON',                        // fixed value
                mode: '{{mode}}',                            // desired mode
                mid: '{{merchantID}}',                       // your MID
                aid: '{{accountID}}',                        // your AID
                portalid: '{{portalID}}',                    // your PortalId
                encoding: 'UTF-8',                           // desired encoding
                storecarddata: 'yes',                        // fixed value
                hash: '{{hash}}'
            };
            var iframes = new Payone.ClientApi.HostedIFrames(config, request);

            document.getElementById('cardtype').onchange = function () {
               iframes.setCardType(this.value);              // on change: set new type of credit card to process
            };

            function check() {                               // Function called by submitting PAY-button
                if (iframes.isComplete()) {
                    iframes.creditCardCheck('checkCallback');// Perform "CreditCardCheck" to create and get a
                                                             // PseudoCardPan; then call your function "checkCallback"
                } else {
                    console.log("not complete");
                }
            }

            function checkCallback(response) {
                console.log(response);
                if (response.status === "VALID") {
                    document.getElementById("pseudocardpan").value = response.pseudocardpan;
                    document.getElementById("truncatedcardpan").value = response.truncatedcardpan;
                }
            }
        </script>
        </body>
        </html>
        """
}
