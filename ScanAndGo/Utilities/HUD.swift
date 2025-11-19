//
//  HUD.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 05.07.24.
//

import SwiftUI
import SnabbleAssetProviding
import SnabbleComponents

struct HUD<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(.regularMaterial)
            .clipShape(CardShape(radius: 16, .top))
    }
}

extension View {
    func hud<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .top) {
            self
            if isPresented.wrappedValue {
                HUD(content: content)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .zIndex(1)
            }
        }
    }
}
