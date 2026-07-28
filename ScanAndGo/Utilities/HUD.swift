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

private struct HUDModifier<HUDContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let hudContent: HUDContent

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if isPresented {
                HUD { hudContent }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.5), value: isPresented)
    }
}

extension View {
    func hud<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(HUDModifier(isPresented: isPresented, hudContent: content()))
    }
}
