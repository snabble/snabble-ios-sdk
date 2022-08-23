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
    @State private var showingAlert = false
//    @EnvironmentObject var model: ShopViewModel

    public var body: some View {
        VStack(alignment: .center) {
            ShopMapView(shop: shop)
            VStack(spacing: 0) {
                ShopAddressView(shop: shop)
            }
            .padding([.top, .bottom], 20)

            HStack {
                Spacer()
                Asset.image(named: "location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                ShopDistanceView(shop: shop)
                Button(action: {
                    showingAlert.toggle()
                }) {
                    Asset.image(named: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.accent())
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Snabble.Shop.Detail.startNavigation"),
                          message: Text("\(shop.street)\n\(shop.postalCode) \(shop.city)"),
                          primaryButton: .destructive(Text("yes")) {
                        ShopViewModel.default.navigate(to: shop)
                    },
                          secondaryButton: .cancel())
                }
                Spacer()
            }
            .padding(.bottom, 20)

            HStack {
                Asset.image(named: "phone")
                Text(shop.phone)
            }
        }
        .navigationTitle(shop.name)
    }
}
