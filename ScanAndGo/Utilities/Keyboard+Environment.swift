//
//  Keyboard+Environment.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 18.06.24.
//

import SwiftUI

private struct KeyboardHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Height of software keyboard when visible
    public var keyboardHeight: CGFloat {
        get { self[KeyboardHeightEnvironmentKey.self] }
        set { self[KeyboardHeightEnvironmentKey.self] = newValue }
    }
}

struct KeyboardHeightEnvironmentValue: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .environment(\.keyboardHeight, keyboardHeight)
            /// Approximation of Apple's keyboard animation
            /// source: https://forums.developer.apple.com/forums/thread/48088
            .animation(.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0), value: keyboardHeight)
            .background {
                GeometryReader { keyboardProxy in
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: keyboardProxy.safeAreaInsets.bottom - proxy.safeAreaInsets.bottom) { _, newValue in
                                DispatchQueue.main.async {
                                    if keyboardHeight != newValue {
                                        keyboardHeight = newValue
                                    }
                                }
                            }
                    }
                    .ignoresSafeArea(.keyboard)
                }
            }
    }
}

public extension View {
    /// Adds an environment value for software keyboard height when visible
    ///
    /// Must be applied on a view taller than the keyboard that touches the bottom edge of the safe area.
    /// Access keyboard height in any child view with
    /// @Environment(\.keyboardHeight) var keyboardHeight
    func keyboardHeightEnvironmentValue() -> some View {
        modifier(KeyboardHeightEnvironmentValue())
    }
}

#Preview {
    VStack {
        TextField("Example", text: .constant(""))
    }
    .keyboardHeightEnvironmentValue()
}
