//
//  PrimaryButtonView.swift
//  teo
//
//  Created by Andreas Osberghaus on 2023-10-10.
//

import SwiftUI

public struct PrimaryButtonView: View {
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
            onAction()
        }) {
            Text(title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle(disabled: disabled))
        .disabled(disabled)
    }
}

#Preview {
    PrimaryButtonView(title: "Hello World!") {
        print("Hello World!")
    }
}
