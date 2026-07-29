//
//  ScannerProcessingView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 04.07.24.
//

import SwiftUI

public struct ScannerProcessingView: View {
    public var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Lade…")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            )
            .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    ScannerProcessingView()
}
