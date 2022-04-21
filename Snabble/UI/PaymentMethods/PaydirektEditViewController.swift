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
        let _self: Link
        let web: Link

        enum CodingKeys: String, CodingKey {
            case _self = "self"
            case web
        }
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
    private weak var webViewWrapper: UIView?
    private weak var displayView: UIView?
    private weak var displayLabel: UILabel?
    private weak var openButton: UIButton?
    private weak var deleteButton: UIButton?

    private weak var webView: WKWebView?
    private var detail: PaymentMethodDetail?
    private weak var analyticsDelegate: AnalyticsDelegate?
    private var clientAuthorization: String?

    private let authData = PaydirektAuthorization(
        id: UIDevice.current.identifierForVendor?.uuidString ?? "",
        name: UIDevice.current.name,
        ipAddress: "127.0.0.1",
        fingerprint: "167-671",
        redirectUrlAfterSuccess: RedirectStatus.success.url,
        redirectUrlAfterCancellation: RedirectStatus.cancelled.url,
        redirectUrlAfterFailure: RedirectStatus.failure.url
    )

    public init(_ detail: PaymentMethodDetail?, with analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground

        let webViewWrapper = UIView()
        webViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        let webView = self.addWebView(to: webViewWrapper)

        let displayView = UIView()
        displayView.translatesAutoresizingMaskIntoConstraints = false

        let displayLabel = UILabel()
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        displayLabel.font = UIFont.systemFont(ofSize: 17)
        displayLabel.textColor = .label
        displayLabel.textAlignment = .natural
        displayLabel.numberOfLines = 0
        displayLabel.text = L10n.Snabble.Paydirekt.savedAuthorization

        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.isUserInteractionEnabled = true
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        openButton.setTitleColor(.link, for: .normal)
        openButton.setTitle(L10n.Snabble.Paydirekt.gotoWebsite, for: .normal)
        openButton.addTarget(self, action: #selector(openButtonTapped(_:)), for: .touchUpInside)

        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        deleteButton.makeSnabbleButton()
        deleteButton.isUserInteractionEnabled = true
        deleteButton.setTitle(L10n.Snabble.Paydirekt.deleteAuthorization, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)

        view.addSubview(webViewWrapper)
        view.addSubview(displayView)

        displayView.addSubview(displayLabel)
        displayView.addSubview(openButton)
        displayView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            webViewWrapper.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webViewWrapper.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webViewWrapper.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webViewWrapper.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            displayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            displayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            displayView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            displayView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            displayLabel.leadingAnchor.constraint(equalTo: displayView.leadingAnchor, constant: 16),
            displayLabel.trailingAnchor.constraint(equalTo: displayView.trailingAnchor, constant: -16),
            displayLabel.topAnchor.constraint(equalTo: displayView.topAnchor, constant: 16),

            openButton.leadingAnchor.constraint(equalTo: displayLabel.leadingAnchor),
            openButton.topAnchor.constraint(equalTo: displayLabel.bottomAnchor, constant: 16),

            deleteButton.heightAnchor.constraint(equalToConstant: 48),
            deleteButton.bottomAnchor.constraint(equalTo: displayView.bottomAnchor, constant: -16),
            deleteButton.leadingAnchor.constraint(equalTo: displayView.leadingAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: displayView.trailingAnchor, constant: -16)
        ])

        self.view = view
        self.webViewWrapper = webViewWrapper
        self.webView = webView
        self.displayView = displayView
        self.displayLabel = displayLabel
        self.openButton = openButton
        self.deleteButton = deleteButton
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = L10n.Snabble.Paydirekt.title
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.detail == nil {
            self.webViewWrapper?.isHidden = false
            self.displayView?.isHidden = true
            self.startAuthorization()
        } else {
            self.webViewWrapper?.isHidden = true
            self.displayView?.isHidden = false
        }
    }

    private func startAuthorization() {
        guard
            let authUrl = Snabble.metadata.links.paydirektCustomerAuthorization?.href,
            let project = Snabble.projects.first
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
                    self.clientAuthorization = authResult.links._self.href
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

    @objc private func openButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://www.paydirekt.de")!)
    }

    @objc private func deleteTapped(_ sender: Any) {
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
                    let cert = Snabble.certificates.first,
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
        navigationController?.popViewController(animated: true)
    }
}
