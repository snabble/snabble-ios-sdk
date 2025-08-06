//
//  YouTubeView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.08.25.
//

import SwiftUI
import WebKit

public extension String {
    var extractYouTubeID: String? {
        guard let url = URL(string: self),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first(where: { $0.name == "v" })?.value
    }
}

public struct YouTubeView: UIViewRepresentable {
    let videoID: String

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
        </head>
        <body>
            <iframe width="100%" height="280px" src="https://www.youtube.com/embed/\(videoID)?playsinline=1" frameborder="0" allowfullscreen></iframe>
        </body>
        </html>
        """
        uiView.loadHTMLString(embedHTML, baseURL: nil)
    }
}
