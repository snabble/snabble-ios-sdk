//
//  ShowCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI

public struct ShopCellView: View {
    var shop: Shop
    var distance: String
    
    @ViewBuilder
    var distanceView: some View {
        if distance.isEmpty {
            EmptyView()
        } else {
            Text(distance)
        }
    }
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(shop.name)
                .fontWeight(.bold)
                VStack(alignment: .leading, spacing: 0) {
                    Text(shop.street)
                    Text("\(shop.postalCode) \(shop.city)")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            Spacer()
            distanceView
        }
    }
}
