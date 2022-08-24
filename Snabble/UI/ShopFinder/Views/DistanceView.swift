//
//  DistanceView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 24.08.22.
//

import Foundation
import SwiftUI

public struct DistanceView: View {
    var distance: Double?

    public var body: some View {
        if let distance = distance?.formatted(), !distance.isEmpty {
            Text(distance)
        } else {
            EmptyView()
        }
    }
}

// stuff for displaying formatted numbers
private extension Double {
    /// format a distance value in meters
    func formatted() -> String? {
        let value: Double
        let format: String
        if self < 1000 {
            value = self
            format = "#0 m"
        } else if self < 100000.0 {
            value = self / 1000.0
            format = "#0.0 km"
        } else {
            value = self / 1000.0
            format = "#0 km"
        }

        let formatter = NumberFormatter()
        formatter.positiveFormat = format
        return formatter.string(for: value)
    }
}
