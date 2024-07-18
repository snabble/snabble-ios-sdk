//
//  View+Dialog.swift
//  SnabbleAssetProviding
//
//  Created by Uwe Tilemann on 12.06.24.
//

import SwiftUI

struct DialogViewModifier<Dialog: View>: ViewModifier {
    /// The binding that determines if the toast is presented
    @Binding var isPresented: Bool
    let dialog: () -> Dialog
    
    /// State to control the visibility of the toast
    @State private var isShowing = false
    @State var transaction = Transaction(animation: .linear)
    @State private var opacity = 0.3
    init(isPresented: Binding<Bool>, @ViewBuilder dialog: @escaping () -> Dialog) {
        self._isPresented = isPresented
        self.dialog = dialog
    }
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented,
                             onDismiss: {
                withTransaction(transaction) {
                    isPresented = false
                    isShowing = false
                }
                
            }) {
                GeometryReader { geometry in
                    ZStack(alignment: .center) {
                        if isShowing {
                            Color.black
                                .opacity(0.3)
                            dialog()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .presentationBackground(.clear)
                .onAppear {
                    withTransaction(transaction) {
                        isShowing = true
                    }
                }
            }
            .transaction { transaction in
                transaction.disablesAnimations = isPresented
            }
            .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

extension View {
    /// Presents a toast message
    /// - Parameters:
    ///   - isPresented: Binding to display the toast
    /// - Returns: A view that presents a toast
    public func dialog<Dialog: View>(isPresented: Binding<Bool>,
                                     @ViewBuilder dialog: @escaping () -> Dialog) -> some View {
        modifier(DialogViewModifier(isPresented: isPresented,
                                    dialog: dialog)
        )
    }
}
