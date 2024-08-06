//
//  View+HUD.swift
//  SnabbleAssetProviding
//
//  Created by Andreas Osberghaus on 2024-05-14.
//

import SwiftUI

struct ToastViewModifier: ViewModifier {
    /// The binding that determines if the toast is presented
    @Binding var isPresented: Bool
    /// Time until the toast is dismissed or `nil` to keep it visible
    let duration: TimeInterval?
    let toast: Toast

    /// State to control the visibility of the toast
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isPresented ? 1 : 0)
            .fullScreenCover(isPresented: $isPresented) {
                GeometryReader { geometry in
                    ZStack(alignment: .center) {
                        if isShowing {
                            Color.black
                                .opacity(0.3)
                            ToastView(toast: toast)
                                .padding(.horizontal, geometry.size.width * 0.2)
                        }
                    }
                    .task {
                        if let duration {
                            await autoDismiss(after: duration)
                        }
                    }
                    .onTapGesture {
                        dismiss()
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .presentationBackground(.clear)
                .onAppear {
                    withAnimation {
                        isShowing = true
                    }
                }
            }
            .transaction { transaction in
                transaction.disablesAnimations = isPresented
            }
    }

    /// Automatically dismisses the toast after the given duration
    private func autoDismiss(after: TimeInterval) async {
        // Delay of `after` seconds (1 second = 1_000_000_000 nanoseconds)
        try? await Task.sleep(nanoseconds: UInt64(after) * 1_500_000_000)
        dismiss()
    }

    /// Dismisses the toast and the full screen cover animated
    private func dismiss() {
        withAnimation(completionCriteria: .logicallyComplete) {
            isShowing = false
        } completion: {
            isPresented = false
        }
    }
}

extension View {
    /// Presents a toast message
    /// - Parameters:
    ///   - isShowing: Binding to display the toast
    ///   - duration: Time until the toast is dismissed or `nil` to keep it visible
    ///   - text: The text to show
    /// - Returns: A view that presents a toast
    public func toast(isPresented: Binding<Bool>,
                      duration: TimeInterval? = 3,
                      toast: Toast
    ) -> some View {
        modifier(ToastViewModifier(isPresented: isPresented,
                                   duration: duration,
                                   toast: toast)
        )
    }
}
