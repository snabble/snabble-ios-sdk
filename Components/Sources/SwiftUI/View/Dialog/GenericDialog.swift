//
//  DialogView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-17.
//

import SwiftUI
import UIKit
import Combine
import WindowKit

public struct GenericDialog<DialogContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval?
    let dialogContent: DialogContent
    
    @State private var workItem: DispatchWorkItem?
    
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
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    dialogContent
                }
                .presentationBackground(.clear)
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
            isPresented = false
        }
        
        workItem?.cancel()
        workItem = nil
    }
}

public extension View {
    func windowDialog<DialogContent: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval? = nil,
        @ViewBuilder content: @escaping () -> DialogContent) -> some View {
            modifier(GenericDialog(
                isPresented: isPresented,
                duration: duration,
                content: content)
            )
        }
}
