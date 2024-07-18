//
//  PaymentButtonView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 08.09.23.
//

import SwiftUI

import SnabbleCore
import SnabbleUI

struct PaymentButtonView: View {
    @ObservedObject var model: Shopper
    let onAction: () -> Void
    
    var body: some View {
        Button(action: {
            onAction()
        }, label: {
            HStack {
                Spacer(minLength: 2)
                if let icon = model.selectedPayment?.method.icon {
                    SwiftUI.Image(uiImage: icon)
                        .animation(.smooth, value: icon)
                } else {
                    Text("")
                }
                Spacer(minLength: 2)
                Image(systemName: "chevron.down")
            }
            .frame(width: 88, height: 24)
            .contentShape(Rectangle())
        })
        .buttonStyle(BorderedButtonStyle())
    }
}

struct BorderedButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 13)
            .padding([.leading, .trailing], 8)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(.accentColor)
            )
    }
}
