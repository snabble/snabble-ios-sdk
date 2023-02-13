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

struct PaddingCircle: Shape {
    var percent: CGFloat
    
    func path(in rect: CGRect) -> Path {
    
        let rectSize = CGSize(width: rect.width - rect.width / 100 * percent, height: rect.height - rect.height / 100 * percent)
        
        var path = Path()
        path.addEllipse(in: CGRect(origin: CGPoint(x: rect.width / 2 - rectSize.width / 2, y: rect.height / 2 - rectSize.height / 2), size: rectSize))
        
        return path
    }
}

struct MultiColorModifier: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, color, color)
        } else {
            content
                .foregroundColor(color)
                .background(Color.white)
                .clipShape(PaddingCircle(percent: 20))
        }
    }
}
extension View {
    func multiColor(_ color: Color) -> some View {
        modifier(MultiColorModifier(color: color))
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
