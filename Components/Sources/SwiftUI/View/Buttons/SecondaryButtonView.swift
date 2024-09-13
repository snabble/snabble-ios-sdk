//
//  SecondaryButtonView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2023-10-10.
//

import SwiftUI

public struct SecondaryButtonView: View {    
    let title: String
    @Binding var disabled: Bool
    
    let onAction: () -> Void
    
    public init(title: String, disabled: Binding<Bool> = .constant(false), onAction: @escaping () -> Void) {
        self.title = title
        self._disabled = disabled
        self.onAction = onAction
    }
    
    public var body: some View {
        Button(action: {
            withAnimation {
                onAction()
            }
        }) {
            Text(title)
                .fontWeight(.bold)
        }
        .buttonStyle(ProjectSecondaryButtonStyle(disabled: disabled))
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

#Preview {
    SecondaryButtonView(title: "Hello World!") {
        print("Hello World!")
    }
}
