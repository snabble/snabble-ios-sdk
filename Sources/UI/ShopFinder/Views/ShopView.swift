//
//  ShopView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SnabbleCore
import SwiftUI

public struct ShopView: View {
    var shop: ShopProviding

    @ObservedObject var viewModel: ShopsViewModel
    @State private var showingAlert = false

    @ViewBuilder
    var distance: some View {        
        if viewModel.isCurrent(shop) {
            Button(action: {
                viewModel.actionPublisher.send(shop)
            }) {
                Text(keyed: "Snabble.Shop.Detail.shopNow")
            }
            .buttonStyle(AccentButtonStyle())
        } else {
            HStack {
                Spacer()
                Asset.image(named: "location")
                    .font(.subheadline)
                    .foregroundColor(.systemGray)
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
    
    @ViewBuilder
    var checkInButton: some View {
        if DeveloperMode.showCheckIn {
            Button(action: {
                DeveloperMode.toggleCheckIn(for: shop)
            }) {
                Text(isCheckedIn() ? "[Check Out]" : "[Check In]")
            }
        }
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                ShopMapView(shop: shop, userLocation: viewModel.locationManager.location)
                    .frame(minHeight: 300)

                VStack(spacing: 0) {
                    checkInButton
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
    
    private func isCheckedIn() -> Bool {
        return Snabble.shared.checkInManager.shop?.id == self.shop.id
    }
}
