//
//  Toast.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import Foundation
import SwiftUI

public struct Toast: Swift.Identifiable, Equatable {
    public let id = UUID()
    /// The text to show
    public let message: String
    /// The `Toast.Style` to show
    public var style: Toast.Style
    /// The duration the toast is shown
    public var duration: TimeInterval
    
    public enum Style {
        case error
        case warning
        case success
    }
    
    public init(message: String, style: Toast.Style = .success, duration: TimeInterval = 3) {
        self.message = message
        self.style = style
        self.duration = duration
    }
}
