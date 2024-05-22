//
//  HTMLView.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 06.03.23.
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    var string: String?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        webView.isOpaque = false
        webView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let string = string else {
            return
        }
        DispatchQueue.main.async {
            uiView.loadHTMLString(string, baseURL: nil)
        }
    }
}

public struct HTMLView: View {
    let string: String

    public var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    WebViewRepresentable(string: string)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}

struct HTMLView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLView(string: "Hello, World!".htmlString())
    }
}
