//
//  HiddenToolbarModifier.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

public struct HiddenToolbarModifier: ViewModifier {
    public func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .toolbar(removing: .title)
        } else {
            content
        }
    }
}

extension View {
    public func hiddenToolbar() -> some View {
        modifier(HiddenToolbarModifier())
    }
}
