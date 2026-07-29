//
//  HUD.swift
//  SnabbleComponents
//
//  Created by Uwe Tilemann on 05.07.24.
//

import SwiftUI

public struct HUD<Content: View>: View {
    @ViewBuilder let content: Content

    public var body: some View {
        content
            .background(.regularMaterial)
            .clipShape(CardShape(radius: 16, .top))
    }
}

private struct HUDModifier<HUDContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let hudContent: HUDContent
    @State private var hudHeight: CGFloat = 60

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            HUD { hudContent }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hudHeight = $0 }
                .offset(y: isPresented ? 0 : -hudHeight)
                .layoutPriority(0)
                .opacity(isPresented ? 1 : 0)
                .allowsHitTesting(isPresented)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        }
    }
}

public extension View {
    func hud<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(HUDModifier(isPresented: isPresented, hudContent: content()))
    }
}
