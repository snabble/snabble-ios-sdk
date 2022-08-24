//
//  ShopDistanceView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 24.08.22.
//

import Foundation
import SwiftUI

public struct ShopDistanceView: View {
    var shop: ShopInfoProvider
    @ObservedObject var viewModel: ShopsViewModel

    public var body: some View {
        if let distance = viewModel.distance(for: shop), !distance.isEmpty {
            Text(distance)
        } else {
            EmptyView()
        }
    }
}
