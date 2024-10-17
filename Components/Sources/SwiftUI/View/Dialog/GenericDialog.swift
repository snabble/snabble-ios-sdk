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
    @Binding var isShowing: Bool
    let dismissOnTapOutside: Bool
    let dismissed: (() -> Void)?
    let duration: TimeInterval
    let dialogContent: DialogContent
    
    @State private var isFullScreenCoverVisible: Bool = false
    
    public init(isShowing: Binding<Bool>,
                dismissOnTapOutside: Bool,
                dismissed: (() -> Void)?,
                duration: TimeInterval,
                @ViewBuilder dialogContent: () -> DialogContent) {
        _isShowing = isShowing
        self.dismissOnTapOutside = dismissOnTapOutside
        self.dismissed = dismissed
        self.duration = duration
        self.dialogContent = dialogContent()
    }
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isShowing) {
                Group {
                    if isFullScreenCoverVisible {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    isFullScreenCoverVisible = false
                                }
                            dialogContent
                        }.onDisappear {
                            isShowing = false
                            dismissed?()
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
    }
}

public extension View {
    func genericDialog<DialogContent: View>(isShowing: Binding<Bool>,
                                            dismissOnTapOutside: Bool = true,
                                            dismissed: (() -> Void)? = nil,
                                            duration: TimeInterval = 0.3,
                                            @ViewBuilder dialogContent: @escaping () -> DialogContent) -> some View {
        self.modifier(GenericDialog(isShowing: isShowing,
                                    dismissOnTapOutside: dismissOnTapOutside,
                                    dismissed: dismissed,
                                    duration: duration,
                                    dialogContent: dialogContent))
    }
    
}
