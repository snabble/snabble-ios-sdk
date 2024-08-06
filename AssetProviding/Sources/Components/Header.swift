//
//  SwiftUIView.swift
//  
//
//  Created by Uwe Tilemann on 16.05.24.
//

import SwiftUI

public struct Header: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

    }
    private var font: Font {
        guard let customFont = Asset.font("SnabbleUI.CustomFont.header", size: 28, relativeTo: .title, domain: nil) else {
            let ctFont = CTFontCreateUIFontForLanguage(.label, 28, nil)!
            return Font(ctFont)
        }
        return customFont
    }
}

public extension View {
    func header() -> some View {
        modifier(Header())
    }
}

#Preview {
    Text("Hello World!")
        .header()
}
