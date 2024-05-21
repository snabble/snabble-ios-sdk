//
//  TextFieldLimitModifer.swift
//
//
//  Created by Andreas Osberghaus on 2024-03-28.
//

import SwiftUI
import Combine

struct TextFieldLimitModifer: ViewModifier {
    @Binding var value: String
    var length: Int?

    func body(content: Content) -> some View {
        content.onChange(of: $value.wrappedValue) {
            if let length {
                value = String($0.prefix(length))
            }
        }
    }
}

extension View {
    func limitInputLength(value: Binding<String>, length: Int?) -> some View {
        modifier(TextFieldLimitModifer(value: value, length: length))
    }
}
