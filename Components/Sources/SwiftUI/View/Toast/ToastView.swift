//
//  Toast.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

public struct ToastView: View {
    
    public var style: Toast.Style
    public var message: String
    
    @State private var animated: Bool = false
    
    public var body: some View {
        VStack(spacing: 12) {
            style.image
                .font(.system(size: 64))
                .foregroundColor(style.color)
                .symbolEffect(.bounce, value: animated)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1))
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            animated = true
        }
    }
}

extension Toast.Style {
    var color: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .success: return Color.white
        }
    }
    
    var image: Image {
        switch self {
        case .warning: return Image(systemName: "exclamationmark.triangle.fill")
        case .success: return Image(systemName: "checkmark.circle.fill")
        case .error: return Image(systemName: "xmark.circle.fill")
        }
    }
}
