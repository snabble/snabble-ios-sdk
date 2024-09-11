//
//  WebView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import SwiftUI

public struct WebView: View {
    public let url: URL
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
