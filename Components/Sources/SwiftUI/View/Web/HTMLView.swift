//
//  HTMLView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import SwiftUI

public struct HTMLView: View {
    public let string: String
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
