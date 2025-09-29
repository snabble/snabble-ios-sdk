//
//  GiropayEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
@preconcurrency import WebKit
import SnabbleCore
import SnabbleAssetProviding

private struct GiropayAuthorizationResult: Decodable {
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

    static let host = "snabble-giropay"

    var url: String {
        return "\(RedirectStatus.host)://\(self.rawValue)"
    }
}

public final class GiropayEditViewController: UIViewController {
    private weak var webViewWrapper: UIView?
    private weak var displayView: UIView?
    private weak var errorView: UIView?

    private weak var webView: WKWebView?
    private var detail: PaymentMethodDetail?
    private weak var analyticsDelegate: AnalyticsDelegate?
    private var clientAuthorization: String?
    private var projectId: Identifier<Project>?

    private let authData = GiropayAuthorization(
        id: UIDevice.current.identifierForVendor?.uuidString ?? "",
        name: UIDevice.current.name,
        ipAddress: "127.0.0.1",
        fingerprint: "167-671",
        redirectUrlAfterSuccess: RedirectStatus.success.url,
        redirectUrlAfterCancellation: RedirectStatus.cancelled.url,
        redirectUrlAfterFailure: RedirectStatus.failure.url
    )

    public init(_ detail: PaymentMethodDetail?, for projectId: Identifier<Project>?, with analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground
        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let webViewWrapper = UIView()
        webViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        let webView = self.addWebView(to: webViewWrapper)

        let displayView = UIView()
        displayView.translatesAutoresizingMaskIntoConstraints = false

        let displayLabel = UILabel()
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        displayLabel.font = .preferredFont(forTextStyle: .body)
        displayLabel.adjustsFontForContentSizeCategory = true
        displayLabel.textColor = .label
        displayLabel.textAlignment = .natural
        displayLabel.numberOfLines = 0
        displayLabel.text = Asset.localizedString(forKey: "Snabble.Giropay.savedAuthorization")

        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.isUserInteractionEnabled = true
        openButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        openButton.titleLabel?.adjustsFontForContentSizeCategory = true
        openButton.setTitleColor(.link, for: .normal)
        openButton.setTitle(Asset.localizedString(forKey: "Snabble.Giropay.gotoWebsite"), for: .normal)
        openButton.addTarget(self, action: #selector(openButtonTapped(_:)), for: .touchUpInside)

        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        deleteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        deleteButton.makeSnabbleButton()
        deleteButton.isUserInteractionEnabled = true
        deleteButton.setTitle(Asset.localizedString(forKey: "Snabble.Giropay.deleteAuthorization"), for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)

        let errorView = UIView()
        errorView.translatesAutoresizingMaskIntoConstraints = false

        let errorLabel = UILabel()
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = .preferredFont(forTextStyle: .body)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .label
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.text = Asset.localizedString(forKey: "Snabble.Giropay.AuthorizationFailed.title")

        let errorButton = UIButton(type: .system)
        errorButton.translatesAutoresizingMaskIntoConstraints = false
        errorButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        errorButton.titleLabel?.adjustsFontForContentSizeCategory = true
        errorButton.setTitle(Asset.localizedString(forKey: "Snabble.PaymentError.tryAgain"), for: .normal)
        errorButton.setTitleColor(.onProjectPrimary(), for: .normal)
        errorButton.makeSnabbleButton()
        errorButton.isUserInteractionEnabled = true
        errorButton.addTarget(self, action: #selector(errorButtonTapped(_:)), for: .touchUpInside)

        view.addSubview(webViewWrapper)
        view.addSubview(displayView)
        view.addSubview(errorView)

        displayView.addSubview(displayLabel)
        displayView.addSubview(openButton)
        displayView.addSubview(deleteButton)

        errorView.addSubview(errorLabel)
        errorView.addSubview(errorButton)

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
            deleteButton.trailingAnchor.constraint(equalTo: displayView.trailingAnchor, constant: -16),

            errorView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -16),
            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor),

            errorButton.heightAnchor.constraint(equalToConstant: 48),
            errorButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 30),
            errorButton.bottomAnchor.constraint(equalTo: errorView.bottomAnchor),
            errorButton.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 16),
            errorButton.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -16)
        ])

        self.view = view
        self.webViewWrapper = webViewWrapper
        self.webView = webView
        self.displayView = displayView
        self.errorView = errorView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = Asset.localizedString(forKey: "Snabble.Giropay.title")
        errorView?.isHidden = true
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
            let authUrl = Snabble.shared.giropayAuthorizationHref,
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId)
        else {
            errorView?.isHidden = false
            Log.error("no paydirektCustomerAuthorization in metadata or no project found")
            return
        }

        project.request(.post, authUrl, body: authData) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (result: Result<GiropayAuthorizationResult, SnabbleError>) in
                Task { @MainActor in
                    switch result {
                    case .success(let authResult):
                        guard let webUrl = URL(string: authResult.links.web.href) else {
                            return
                        }
                        
                        self.webView?.load(URLRequest(url: webUrl))
                        self.clientAuthorization = authResult.links._self.href
                    case .failure(let error):
                        self.errorView?.isHidden = false
                        print(error)
                    }
                }
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    @MainActor @objc private func openButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://www.giropay.de")!)
    }

    @objc private func deleteTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.Payment.Delete.message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted("giropay"))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    @objc private func errorButtonTapped(_ sender: Any) {
        startAuthorization()
    }

    private func addWebView(to superview: UIView) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 14, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
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

extension GiropayEditViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("navigation action: \(navigationAction)")

        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }

        // handle our redirect URLs
        if let requestUrl = navigationAction.request.url?.absoluteString {
            switch requestUrl {
            case RedirectStatus.success.url:
                guard
                    let cert = Snabble.shared.certificates.first,
                    let auth = self.clientAuthorization,
                    let data = GiropayData(cert.data, auth, self.authData)
                else {
                    return
                }

                let detail = PaymentMethodDetail(data)
                PaymentMethodDetails.save(detail)

                self.goBack()
            case RedirectStatus.failure.url:
                self.clientAuthorization = nil
                let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Giropay.AuthorizationFailed.title"),
                                              message: Asset.localizedString(forKey: "Snabble.Giropay.AuthorizationFailed.message"),
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
