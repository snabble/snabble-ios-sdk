//
//  GenericCenteredView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-08.
//
import SwiftUI

public struct GenericCenteredView<Top: View, Middle: View, Bottom: View>: View {
    public let top: Top?
    public let middle: Middle?
    public let bottom: Bottom?
    
    public init(top: () -> Top, middle: () -> Middle, bottom: () -> Bottom) {
        self.top = top()
        self.middle = middle()
        self.bottom = bottom()
    }
    
    public init(top: () -> Top, middle: () -> Middle) where Bottom == Never {
        self.top = top()
        self.middle = middle()
        self.bottom = nil
    }
    
    public var body: some View {
        VStack {
            Spacer()
            if let top {
                top
            }
            if let middle {
                middle
            }
            if let bottom {
                bottom
            }
            Spacer()
        }
    }
}
