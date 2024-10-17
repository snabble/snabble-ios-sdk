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
    let duration: TimeInterval
    let dialogContent: DialogContent
    
    @State private var isFullscreenCoverPresented: Bool = false
    @State private var isFullScreenCoverVisible: Bool = false
    
    public init(isPresented: Binding<Bool>,
                onDismiss: (() -> Void)?,
                duration: TimeInterval,
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
                }
            }
            .transaction({ transaction in
                transaction.disablesAnimations = true
                transaction.animation = .linear(duration: duration)
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
}

public extension View {
    func genericDialog<DialogContent: View>(isPresented: Binding<Bool>,
                                            onDismiss: (() -> Void)? = nil,
                                            duration: TimeInterval = 0.3,
                                            @ViewBuilder content: @escaping () -> DialogContent) -> some View {
        modifier(GenericDialog(
            isPresented: isPresented,
            onDismiss: onDismiss,
            duration: duration,
            content: content)
        )
    }
}
