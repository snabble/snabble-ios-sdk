//
//  AnimatedButtonStyle.swift
//  
//
//  Created by Uwe Tilemann on 03.02.23.
//

import SwiftUI

public struct AnimatedButtonStyle: ButtonStyle {
    var selected: Bool
    
    public init(selected: Bool) {
        self.selected = selected
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(.easeOut, value: (configuration.isPressed && selected))
    }
}
