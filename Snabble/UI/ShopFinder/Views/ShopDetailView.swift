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

    @ObservedObject var viewModel: ShopViewModel
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
                ShopDistanceView(shop: shop, viewModel: viewModel)
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
