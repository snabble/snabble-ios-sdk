//
//  WebViewController.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 16.09.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import WebKit

class WebViewController: UIViewController {
    var webView: WKWebView? {
        view as? WKWebView
    }
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?

    let url: URL

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let webView = WKWebView()
        webView.navigationDelegate = self

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.color = .accent()
        activityIndicatorView.hidesWhenStopped = true

        webView.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView?.load(URLRequest(url: url))
        webView?.allowsBackForwardNavigationGestures = true
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicatorView?.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView?.stopAnimating()
    }
}
