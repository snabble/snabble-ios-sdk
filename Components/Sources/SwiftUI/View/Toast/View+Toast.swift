//
//  View+HUD.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

extension View {
    /// Presents a toast message
    public func toast(item toast: Binding<Toast?>, duration: TimeInterval = 3) -> some View {
        let isPresented = Binding<Bool>(get: { toast.wrappedValue != nil }, set: { _ in })
        
        return modifier(GenericDialog(
            isPresented: isPresented,
            onDismiss: { toast.wrappedValue = nil },
            duration: duration,
            content: {
                if let toast = toast.wrappedValue {
                    ToastView(toast: toast)
                }
            })
        )
    }
}
