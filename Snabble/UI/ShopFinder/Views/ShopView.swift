//
//  ShopView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import SwiftUI

extension ShopsViewModel {
    func shopNow() {
    }
}

public struct ShopView: View {
    var shop: ShopProviding

    @ObservedObject var viewModel: ShopsViewModel
    @State private var showingAlert = false

    @ViewBuilder
    var distance: some View {        
        if viewModel.isCurrent(shop) {
            Button(action: {
                viewModel.shopNow()
            }) {
                Text(keyed: "Snabble.Shop.Detail.shopNow")
            }
            .buttonStyle(AccentButtonStyle())
        } else {
            HStack {
                Spacer()
                Asset.image(named: "location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                DistanceView(distance: viewModel.distance(from: shop))
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
        }
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                ShopMapView(shop: shop, userLocation: viewModel.locationManager.location)
                    .frame(minHeight: 300)

                VStack(spacing: 0) {
                    AddressView(provider: shop)
                }
                .font(.body)

                distance
                    .font(.body)

                PhoneNumberView(phone: shop.phone)
                    .font(.body)

                OpeningHoursView(shop: shop)
            }
        }
        .navigationTitle(shop.name)
    }
}
