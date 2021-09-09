//
//  PaydirektEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WebKit

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
    @IBOutlet private var webViewWrapper: UIView!
    @IBOutlet private var displayView: UIView!
    @IBOutlet private var displayLabel: UILabel!
    @IBOutlet private var openButton: UIButton!
    @IBOutlet private var deleteButton: UIButton!

    private var webView: WKWebView?
    private var detail: PaymentMethodDetail?
    private weak var analyticsDelegate: AnalyticsDelegate?
    private var clientAuthorization: String?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    private let authData = PaydirektAuthorization(
        id: UIDevice.current.identifierForVendor?.uuidString ?? "",
        name: UIDevice.current.name,
        ipAddress: "127.0.0.1",
        fingerprint: "167-671",
        redirectUrlAfterSuccess: RedirectStatus.success.url,
        redirectUrlAfterCancellation: RedirectStatus.cancelled.url,
        redirectUrlAfterFailure: RedirectStatus.failure.url
    )

    public init(_ detail: PaymentMethodDetail?, _ analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "paydirekt"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.webView = self.addWebView(to: self.webViewWrapper)

        self.displayLabel.text = L10n.Snabble.Paydirekt.savedAuthorization

        self.deleteButton.makeSnabbleButton()
        self.deleteButton.setTitle(L10n.Snabble.Paydirekt.deleteAuthorization, for: .normal)

        self.openButton.setTitle(L10n.Snabble.Paydirekt.gotoWebsite, for: .normal)

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
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
        guard
            let authUrl = SnabbleAPI.metadata.links.paydirektCustomerAuthorization?.href,
            let project = SnabbleAPI.projects.first
        else {
            Log.error("no paydirektCustomerAuthorization in metadata or no project found")
            return
        }

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
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: L10n.Snabble.Payment.Delete.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.yes, style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted("paydirekt"))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: L10n.Snabble.no, style: .cancel, handler: nil))

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
                let alert = UIAlertController(title: L10n.Snabble.Paydirekt.AuthorizationFailed.title,
                                              message: L10n.Snabble.Paydirekt.AuthorizationFailed.message,
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
            self.navigationController?.popViewController(animated: true)
        } else {
            self.navigationDelegate?.goBack()
        }
    }
}

// stuff that's only used by the RN wrapper
extension PaydirektEditViewController: ReactNativeWrapper {
    public func setDetail(_ detail: PaymentMethodDetail) {
        self.detail = detail
    }
}
