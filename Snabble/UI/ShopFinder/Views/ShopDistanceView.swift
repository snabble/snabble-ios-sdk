//
//  ShopDistanceView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 24.08.22.
//

import Foundation
import SwiftUI

public struct ShopDistanceView: View {
    var distance: String?

    public var body: some View {
        if let distance = distance, !distance.isEmpty {
            Text(distance)
        } else {
            EmptyView()
        }
    }
}
