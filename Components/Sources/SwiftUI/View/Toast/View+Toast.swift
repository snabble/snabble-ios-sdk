//
//  View+HUD.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    
    @Binding var toast: Toast?
    @State private var dismissTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .blur(radius: toast != nil ? 1 : 0)
            .overlay(
                toastView()
                    .animation(.spring(), value: toast)
            )
            .onChange(of: toast) { _, newValue in
                if let newValue  {
                    showToast(newValue)
                }
            }
    }
    
    @ViewBuilder private func toastView() -> some View {
        if let toast = toast {
            ZStack() {
                Color.black
                    .opacity(0.3)
                GeometryReader { geometry in
                    ToastView(toast: toast)
                    .padding(.horizontal, geometry.size.width * 0.2)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .ignoresSafeArea()
            .onTapGesture {
                dismissToast()
            }
        }
    }
    
    private func showToast(_ toast: Toast) {
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()

        if toast.duration > 0 {
            dismissTask?.cancel()
            dismissTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(toast.duration))
                    dismissToast()
                } catch {
                    // Task was cancelled
                }
            }
        }
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }

        dismissTask?.cancel()
        dismissTask = nil
    }
}

extension View {
    /// Presents a toast message
    public func toast(item toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
