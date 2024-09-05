//
//  WebView.swift
//  SnabbleComponents
//
//  Created by Andreas Osberghaus on 05.09.24.
//
//  Copyright © 2024 snabble. All rights reserved.
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

public struct WebView: View {
    let url: URL
    @State private var refreshURL: Bool = false

    public init(url: URL) {
        self.url = url
    }
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    WebViewRepresentable(url: url, refresh: $refreshURL)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}

public struct HTMLView: View {
    let string: String
    @State private var refreshURL: Bool = false

    public init(string: String) {
        self.string = string
    }
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    WebViewRepresentable(string: string, refresh: $refreshURL)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}
