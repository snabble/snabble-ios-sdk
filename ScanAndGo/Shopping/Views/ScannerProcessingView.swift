//
//  ScannerProcessingView.swift
//  Quartier
//
//  Created by Uwe Tilemann on 04.07.24.
//

import SwiftUI

struct ScannerProcessingView: View {
    var body: some View {
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
