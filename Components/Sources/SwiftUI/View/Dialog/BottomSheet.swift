//
//  BottomSheet.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.10.24.
//

import SwiftUI
import UIKit
import Combine
import WindowKit

public struct BottomSheet<DialogContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dialogContent: DialogContent
    
    @State private var showContent: Bool = false
    
    public init(isPresented: Binding<Bool>,
                @ViewBuilder content: () -> DialogContent) {
        _isPresented = isPresented
        self.dialogContent = content()
    }
    
    public func body(content: Content) -> some View {
        content
            .windowCover(isPresented: $isPresented) {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onAppear {
                            showContent = true
                        }
                }
            } configure: { configuration in
                configuration.modalPresentationStyle = .custom
                configuration.modalTransitionStyle = .crossDissolve
            }
            .windowCover(isPresented: $showContent) {
                ZStack {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    VStack {
                        Spacer()
                        dialogContent
                    }
                }
            }
            .onChange(of: isPresented) {
                if !isPresented, showContent {
                    showContent = false
                }
            }
    }
}

public extension View {
    func bottomSheet<DialogContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> DialogContent) -> some View {
            modifier(BottomSheet(
                isPresented: isPresented,
                content: content)
            )
        }
}
