//
//  HTMLView.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 06.03.23.
//

import SwiftUI
import WebKit

private struct WebViewRepresentable: UIViewRepresentable {
    let string: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(string, baseURL: nil)
    }
}

struct HTMLView: View {
    let string: String

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                WebViewRepresentable(string: string)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
