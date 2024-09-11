//
//  WebViewPresentable.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    var url: URL?
    var string: String?
    
    @Binding var refresh: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self, refresh: $refresh)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = self.url {
            uiView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else if let string = self.string {
            uiView.loadHTMLString(string, baseURL: self.url)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        var isFinished = false

        @Binding var refresh: Bool

        init(_ uiWebView: WebViewRepresentable, refresh: Binding<Bool>) {
            self.parent = uiWebView
            _refresh = refresh
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {}

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded so no need to show loader anymore
            if isFinished == false {
                isFinished = true
            }
        }
    }
}
