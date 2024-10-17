//
//  DialogView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-17.
//

import SwiftUI
import UIKit
import Combine

public struct GenericDialog<DialogContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let duration: TimeInterval?
    let dialogContent: DialogContent
    
    @State private var isFullscreenCoverPresented: Bool = false
    @State private var isFullScreenCoverVisible: Bool = false
    
    @State private var workItem: DispatchWorkItem?
    
    public init(isPresented: Binding<Bool>,
                onDismiss: (() -> Void)?,
                duration: TimeInterval?,
                @ViewBuilder content: () -> DialogContent) {
        _isPresented = isPresented
        self.onDismiss = onDismiss
        self.duration = duration
        self.dialogContent = content()
    }
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isFullscreenCoverPresented) {
                Group {
                    if isFullScreenCoverVisible {
                        ZStack {
                            Color.black.opacity(0.2)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    isFullScreenCoverVisible = false
                                }
                            dialogContent
                        }.onDisappear {
                            isFullscreenCoverPresented = false
                            onDismiss?()
                        }
                        .presentationBackground(.clear)
                    }
                }
                .onAppear {
                    isFullScreenCoverVisible = true
                    enableAutomaticDismiss(duration: duration)
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                }
            }
            .transaction({ transaction in
                transaction.disablesAnimations = true
                transaction.animation = .linear(duration: 0.3)
            })
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    isFullscreenCoverPresented = true
                } else {
                    isFullScreenCoverVisible = false
                }
            }
            .onChange(of: isFullscreenCoverPresented) { _, newValue in
                if !newValue {
                    isPresented = false
                }
            }
    }
    
    private func enableAutomaticDismiss(duration: TimeInterval?) {
        if let duration, duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismiss()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
        }
    }
    
    private func dismiss() {
        withAnimation {
            isFullScreenCoverVisible = false
        }
        
        workItem?.cancel()
        workItem = nil
    }
}

public extension View {
    func genericDialog<DialogContent: View>(isPresented: Binding<Bool>,
                                     onDismiss: (() -> Void)? = nil,
                                     duration: TimeInterval? = nil,
                                     @ViewBuilder content: @escaping () -> DialogContent) -> some View {
        modifier(GenericDialog(
            isPresented: isPresented,
            onDismiss: onDismiss,
            duration: duration,
            content: content)
        )
    }
}
