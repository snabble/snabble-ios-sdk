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
    @Binding var isPresented: Bool
    
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
                    .onTapGesture {
                        isPresented = false
                    }
            }
            .padding()
        }
    }
}

#Preview {
    ScanMessageView(message: ScanMessage("Hello World"), isPresented: .constant(true))
}
