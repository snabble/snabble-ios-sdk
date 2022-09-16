//
//  WebView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.01.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    var url: URL
    @Binding var refresh: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self, refresh: $refresh)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
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
