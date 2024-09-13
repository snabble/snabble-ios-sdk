//
//  SwiftUIView.swift
//  
//
//  Created by Uwe Tilemann on 16.05.24.
//

import SwiftUI
import SnabbleAssetProviding

struct HeaderViewModifier: ViewModifier {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color ?? .projectPrimary())
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
    
    private var color: Color? {
        guard let uiColor = Asset.color(named: "SnabbleUI.CustomColor.header") else {
            return nil
        }
        return Color(uiColor: uiColor)
    }
}

public extension View {
    func header() -> some View {
        modifier(HeaderViewModifier())
    }
}

#Preview {
    Text("Hello World!")
        .header()
}
