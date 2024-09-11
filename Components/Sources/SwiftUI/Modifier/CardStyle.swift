//
//  CardStyle.swift
//  SnabbleAssetProviding
//
//  Created by Uwe Tilemann on 16.06.24.
//

import SwiftUI

struct CardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.tertiarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 6, x: 0, y: 0)
    }
}
extension View {
    public func cardStyle() -> some View {
        modifier(CardViewModifier())
    }
}
