//
//  Toast.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

public struct ToastView: View {
    /// The text to show
    public let toast: Toast
    
    /// State to control the animation of the checkmark
    @State private var animated: Bool = false

    public var body: some View {
        VStack(spacing: 8) {
            toast.image
                .font(.system(size: 64))
                .foregroundColor(toast.style == .warning ? .yellow : toast.style == .error ? .red : .white)
                .symbolEffect(.bounce, value: animated)
            Text(toast.text)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1))
        .foregroundColor(.white)
        .cornerRadius(20)
        .task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            animated = true
        }
    }
}

extension Toast {
    var image: SwiftUI.Image {
        switch style {
        case .information:
            Image(systemName: "checkmark.circle")
        case .warning:
            Image(systemName: "exclamationmark.triangle")
        case .error:
            Image(systemName: "xmark.circle")
        }
    }
}
