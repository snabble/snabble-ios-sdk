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
                mainToastView()
                    .animation(.spring(), value: toast)
            )
            .ignoresSafeArea()
            .onChange(of: toast) { oldvalue, newValue in
                showToast()
            }
    }
    
    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            ZStack() {
                Color.black
                    .opacity(0.3)
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        ToastView(
                            style: toast.style,
                            message: toast.message)
                        .padding(.horizontal, geometry.size.width * 0.2)
                        Spacer()
                    }
                }
            }
            .onTapGesture {
                dismissToast()
            }
        }
    }
    
    private func showToast() {
        guard let toast = toast else { return }
        
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
