//
//  Toast.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import Foundation

public struct Toast: Swift.Identifiable, Equatable {
    public let id = UUID()
    /// The text to show
    public let text: String
    /// The `Toast.Style` to show
    public var style: Toast.Style = .information
    
    public enum Style {
        case information
        case warning
        case error
    }
    public init(text: String, style: Toast.Style = .information) {
        self.text = text
        self.style = style
    }
}
