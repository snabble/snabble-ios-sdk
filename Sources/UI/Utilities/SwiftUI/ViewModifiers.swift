//
//  ViewModifiers.swift
//  
//
//  Created by Uwe Tilemann on 03.02.23.
//

import SwiftUI

struct ClearBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func clearBackground() -> some View {
        modifier(ClearBackgroundModifier())
    }
}

struct DoneKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .submitLabel(.done)
        } else {
            content
        }
    }
}
extension View {
    func doneKeyboard() -> some View {
        modifier(DoneKeyboardModifier())
    }
}
