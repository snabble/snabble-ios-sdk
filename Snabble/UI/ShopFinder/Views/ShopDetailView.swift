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
                Button(action: {
                    print("show location")
                }) {
                    SwiftUI.Image(systemName: "house.fill")
                        .font(.title2)
                }
                ShopDistanceView(shop: shop)
                    .padding([.leading, .trailing], 40)
                Button(action: {
                    print("route")
                }) {
                    SwiftUI.Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.title2)
                }
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
