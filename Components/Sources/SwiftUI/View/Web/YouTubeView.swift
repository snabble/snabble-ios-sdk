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

    public init(videoID: String) {
        self.videoID = videoID
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)") else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("http://io.snabble.sdk", forHTTPHeaderField: "Referer")
        
        uiView.load(request)
    }
}
