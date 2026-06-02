//
//  DialogView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-17.
//

import SwiftUI
import UIKit
import WindowKit

public struct WindowDialog<DialogContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval?
    let dialogContent: DialogContent
    
    @State private var dismissTask: Task<Void, Never>?
    
    public init(isPresented: Binding<Bool>,
                duration: TimeInterval?,
                @ViewBuilder content: () -> DialogContent) {
        _isPresented = isPresented
        self.duration = duration
        self.dialogContent = content()
    }
    
    public func body(content: Content) -> some View {
        content
            .windowCover(isPresented: $isPresented) {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    dialogContent
                }
                .onAppear {
                    enableAutomaticDismiss(duration: duration)
                }
            } configure: { configuration in
                configuration.modalPresentationStyle = .custom
                configuration.modalTransitionStyle = .crossDissolve
            }
    }
    
    private func enableAutomaticDismiss(duration: TimeInterval?) {
        if let duration, duration > 0 {
            dismissTask?.cancel()
            dismissTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(duration))
                    dismiss()
                } catch {
                    // Task was cancelled
                }
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }

        dismissTask?.cancel()
        dismissTask = nil
    }
}

public extension View {
    func windowDialog<DialogContent: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval? = nil,
        @ViewBuilder content: @escaping () -> DialogContent) -> some View {
            modifier(WindowDialog(
                isPresented: isPresented,
                duration: duration,
                content: content)
            )
        }
}
