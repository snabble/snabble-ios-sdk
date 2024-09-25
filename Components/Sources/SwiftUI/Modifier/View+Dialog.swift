//
//  View+Dialog.swift
//  SnabbleAssetProviding
//
//  Created by Uwe Tilemann on 12.06.24.
//

import SwiftUI

struct DialogViewModifier<DialogContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let opacity: Double
    let dialogContent: DialogContent
    
    init(isPresented: Binding<Bool>,
         opacity: Double = 0.3,
         @ViewBuilder dialogContent: () -> DialogContent)
    {
        _isPresented = isPresented
        self.opacity = opacity
        self.dialogContent = dialogContent()
    }
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isPresented ? 1 : 0)
            .overlay(
                contentView
                    .animation(.spring(), value: isPresented)
            )
        
    }
    
    @ViewBuilder var contentView: some View {
        if isPresented {
            ZStack(alignment: .center) {
                Color.black
                    .opacity(opacity)
                GeometryReader { geometry in
                    dialogContent
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
            }
            .ignoresSafeArea()
        }
    }
}

extension View {
    public func dialog<DialogContent: View>(
        isPresented: Binding<Bool>,
        opacity: Double = 0.3,
        @ViewBuilder dialogContent: @escaping () -> DialogContent
    ) -> some View {
        modifier(DialogViewModifier(
            isPresented: isPresented,
            opacity: opacity,
            dialogContent: dialogContent)
        )
    }
}
