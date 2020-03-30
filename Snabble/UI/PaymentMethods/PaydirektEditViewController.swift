//
//  PaydirektEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit

// TODO: remove ipAddress and fingerprint
// TODO: if there are multiple bank accounts in one PD account, how/where do we figure out which account to use?

struct PaydirektAuthorization: Encodable {
    let id: String
    let name: String
    let ipAddress: String
    let fingerprint: String

    let redirectUrlAfterSuccess: String
    let redirectUrlAfterCancellation: String
    let redirectUrlAfterFailure: String
}

private struct PaydirektAuthorizationResult: Decodable {
    let id: String
    let links: AuthLinks

    struct AuthLinks: Decodable {
        let `self`: Link
        let web: Link
    }
}

private enum RedirectStatus: String {
    case success
    case cancelled
    case failure

    static let host = "snabble-paydirekt"

    var url: String {
        return "\(RedirectStatus.host)://\(self.rawValue)"
    }
}

public final class PaydirektEditViewController: UIViewController {

    @IBOutlet private weak var webViewWrapper: UIView!
    @IBOutlet private weak var displayView: UIView!
    @IBOutlet private weak var displayLabel: UILabel!
    @IBOutlet private weak var openButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!

    private var webView: WKWebView?
    private var detail: PaydirektData?
    private var index: Int? = 0
    private weak var analyticsDelegate: AnalyticsDelegate?
    private var clientAuthorization: String?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?
    public var backLevels = 1

    private let authData = PaydirektAuthorization(
        id: UIDevice.current.identifierForVendor?.uuidString ?? "",
        name: UIDevice.current.name,
        ipAddress: "127.0.0.1",
        fingerprint: "167-671",
        redirectUrlAfterSuccess: RedirectStatus.success.url,
        redirectUrlAfterCancellation: RedirectStatus.cancelled.url,
        redirectUrlAfterFailure: RedirectStatus.failure.url
    )

    init(_ detail: PaydirektData?, _ index: Int?, _ analyticsDelegate: AnalyticsDelegate?) {
        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.detail = detail
        self.index = index
        self.analyticsDelegate = analyticsDelegate

        self.title = "paydirekt"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.webView = self.addWebView(to: self.webViewWrapper)

        self.displayLabel.text = "Snabble.paydirekt.savedAuthorization".localized()

        self.deleteButton.makeSnabbleButton()
        self.deleteButton.setTitle("Snabble.paydirekt.deleteAuthorization".localized(), for: .normal)

        self.openButton.setTitle("Snabble.paydirekt.gotoWebsite".localized(), for: .normal)

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil)
            Log.error(msg)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.detail == nil {
            self.webViewWrapper.isHidden = false
            self.displayView.isHidden = true
            self.startAuthorization()
        } else {
            self.webViewWrapper.isHidden = true
            self.displayView.isHidden = false
        }
    }

    private func startAuthorization() {
        guard let authUrl = SnabbleAPI.metadata.links.paydirektCustomerAuthorization?.href else {
            Log.error("no paydirektCustomerAuthorization in metadata")
            return
        }

        let project = SnabbleUI.project
        project.request(.post, authUrl, body: authData) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (result: Result<PaydirektAuthorizationResult, SnabbleError>) in
                switch result {
                case .success(let authResult):
                    guard let webUrl = URL(string: authResult.links.web.href) else {
                        return
                    }

                    self.webView?.load(URLRequest(url: webUrl))
                    self.clientAuthorization = authResult.links.`self`.href
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    @IBAction private func paydirektTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://www.paydirekt.de")!)
    }

    @IBAction private func deleteTapped(_ sender: Any) {
        guard let index = self.index else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Snabble.Payment.delete.message".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            PaymentMethodDetails.remove(at: index)
            self.analyticsDelegate?.track(.paymentMethodDeleted("paydirekt"))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    private func addWebView(to superview: UIView) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.minimumFontSize = 15
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = self

        webView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(webView)
        superview.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        superview.rightAnchor.constraint(equalTo: webView.rightAnchor).isActive = true
        superview.bottomAnchor.constraint(equalTo: webView.bottomAnchor).isActive = true
        superview.leftAnchor.constraint(equalTo: webView.leftAnchor).isActive = true

        return webView
    }
}

extension PaydirektEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("navigation action: \(navigationAction)")

        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // handle our redirect URLs
        if let requestUrl = navigationAction.request.url?.absoluteString {
            switch requestUrl {
            case RedirectStatus.success.url:
                guard
                    let cert = SnabbleAPI.certificates.first,
                    let auth = self.clientAuthorization,
                    let data = PaydirektData(cert.data, auth, self.authData)
                else {
                    return
                }

                let detail = PaymentMethodDetail(data)
                PaymentMethodDetails.save(detail)

                self.goBack()
            case RedirectStatus.failure.url:
                self.clientAuthorization = nil
                let alert = UIAlertController(title: "Snabble.paydirekt.authorizationFailed.title".localized(),
                                              message: "Snabble.paydirekt.authorizationFailed.message".localized(),
                                              preferredStyle: .alert)

                self.present(alert, animated: true)
                self.goBack()
            case RedirectStatus.cancelled.url:
                self.clientAuthorization = nil
                self.goBack()
            default:
                break
            }
        }

        decisionHandler(.allow)
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            self.navigationController?.popToInstanceOf(PaymentMethodListViewController.self, animated: true)
        } else {
            self.navigationDelegate?.goBack()
        }
    }
}

// stuff that's only used by the RN wrapper
extension PaydirektEditViewController: ReactNativeWrapper {
    public func setDetail(_ detail: PaymentMethodDetail, _ index: Int) {
        guard case .paydirektAuthorization(let data) = detail.methodData else {
            return
        }

        self.detail = data
        self.index = index
    }
}
