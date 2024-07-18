//
//  ScanMessageView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 16.06.24.
//

import SwiftUI

import SnabbleUI

struct ScanMessageView: View {
    var message: ScanMessage?
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                Text(message?.text ?? "")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
                SwiftUI.Image(systemName: "xmark")
                    .padding()
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ScanMessageView(message: ScanMessage("Hello World"))
}
