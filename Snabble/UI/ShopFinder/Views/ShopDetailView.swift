//
//  ShopDetailView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import SwiftUI
import MapKit

public struct ShopDetailView: View {
    var shop: Shop
    var distance: String
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    public var body: some View {
        VStack(alignment: .center) {
            Map(coordinateRegion: $region)
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
                ShopDistanceView(shop: shop, distance: distance)
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
        .onAppear {
            region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: shop.latitude, longitude: shop.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        }
    }
}
