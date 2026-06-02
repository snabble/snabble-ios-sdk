//
//  UIScreen+Brightness.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2025-01-08.
//
import UIKit

public extension UIScreen {
    private static var previousBrightness: CGFloat?
    
    // Set the screen brightness temporarily
    func setTemporaryBrightness(to value: CGFloat) {
        if UIScreen.previousBrightness == nil {
            UIScreen.previousBrightness = self.brightness
        }
        self.brightness = value
    }
    
    // Reset the screen brightness to the previous value
    func resetBrightness() {
        if let previousBrightness = UIScreen.previousBrightness {
            self.brightness = previousBrightness
            UIScreen.previousBrightness = nil
        }
    }
}
