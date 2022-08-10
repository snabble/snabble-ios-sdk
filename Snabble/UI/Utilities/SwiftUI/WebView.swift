//
//  WebView.swift
//  CarPass
//
//  Created by Uwe Tilemann on 17.01.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
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
        var parent: WebView
        var isFinished = false

        @Binding var refresh: Bool

        init(_ uiWebView: WebView, refresh: Binding<Bool>) {
            self.parent = uiWebView
            _refresh = refresh
        }

        deinit {
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            print("WebView didCommit")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded so no need to show loader anymore
            print("WebView didFinish")
            if isFinished == false {
                isFinished = true
            }
        }
    }
}

struct ShowWebView: View {
    let url: URL
    @State private var refreshURL: Bool = false

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    WebView(url: url, refresh: $refreshURL)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}
