//
//  AnimatedButtonStyle.swift
//  
//
//  Created by Uwe Tilemann on 03.02.23.
//

import SwiftUI

struct AnimatedButtonStyle: ButtonStyle {
    var selected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(.easeOut, value: (configuration.isPressed && selected))
    }
}
