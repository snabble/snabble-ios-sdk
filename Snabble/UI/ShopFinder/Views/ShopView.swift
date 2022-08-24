//
//  ShopView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import SwiftUI

public struct ShopView: View {
    var shop: ShopProviding

    @ObservedObject var viewModel: ShopsViewModel
    @State private var showingAlert = false

    public var body: some View {
        VStack(alignment: .center) {
            ShopMapView(shop: shop, viewModel: viewModel)
            VStack(spacing: 0) {
                AddressView(provider: shop)
            }
            .padding([.top, .bottom], 20)

            HStack {
                Spacer()
                Asset.image(named: "location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                DistanceView(distance: viewModel.distance(for: shop))
                Button(action: {
                    showingAlert.toggle()
                }) {
                    Asset.image(named: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.accent())
                }
                .navigateToShopAlert(isPresented: $showingAlert, shop: shop)
                Spacer()
            }
            .padding(.bottom, 20)

            PhoneNumberView(phone: shop.phone)
        }
        .navigationTitle(shop.name)
    }
}
