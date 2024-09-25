//
//  View+HUD.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
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
                    .ignoresSafeArea()
                GeometryReader { geometry in
                    ToastView(
                        style: toast.style,
                        message: toast.message)
                    .padding(.horizontal, geometry.size.width * 0.2)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .onTapGesture {
                dismissToast()
            }
        }
    }
    
    private func showToast(_ toast: Toast) {
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
        
        if toast.duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismissToast()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    /// Presents a toast message
    public func toastView(toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
