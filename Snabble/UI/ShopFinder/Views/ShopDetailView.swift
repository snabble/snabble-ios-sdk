//
//  ShopDetailView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import SwiftUI

public struct ShopDetailView: View {
    var shop: ShopInfoProvider
    
    public var body: some View {
        VStack(alignment: .center) {
            ShopMapView(shop: shop)
            VStack(spacing: 0) {
                ShopAddressView(shop: shop)
            }
            .padding([.top, .bottom], 20)

            HStack {
                Spacer()
                SwiftUI.Image(systemName: "location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                ShopDistanceView(shop: shop)
                Button(action: {
                    print("route")
                }) {
                    SwiftUI.Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.accent())
                }
                Spacer()
            }
            .padding(.bottom, 20)

            HStack {
                SwiftUI.Image(systemName: "phone")
                Text(shop.phone)
            }
        }
        .navigationTitle(shop.name)
    }
}
