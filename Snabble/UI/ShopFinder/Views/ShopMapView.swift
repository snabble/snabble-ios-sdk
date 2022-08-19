//
//  ShopMapView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.08.22.
//

import Foundation
import SwiftUI
import MapKit

struct ShopLocation: Swift.Identifiable {
    var id = UUID()
    
    let shop: ShopInfoProvider
}

public struct AnnotationView: View {
    var shopLocation: ShopLocation
    @State private var showTitle = true

    @ViewBuilder
    var mapMarker: some View {
        if let image = Asset.image(named: "Snabble.Shop.Detail.mapPin") {
            image
                .padding(1)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Group {
                SwiftUI.Image(systemName: "mappin.and.ellipse")
                    .font(.title)
            }
        }
    }

    public var body: some View {
        VStack {
            VStack(spacing: -2) {
                HStack {
                    Button(action: {
                        print("start navigation?")
                    }) {
                        SwiftUI.Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(8)
                            .background(Color.accent())
                            .foregroundColor(.white)
                            .cornerRadius(4)
                   }
                    VStack(alignment: .leading, spacing: 0) {
                        ShopAddressView(shop: shopLocation.shop)
                    }
                }
                .padding(5)
                .background(Color(.white))
                .cornerRadius(8)
                
                SwiftUI.Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.white)
            }
            .font(.callout)
            .opacity(showTitle ? 0 : 1)
            
            mapMarker
                .foregroundColor(Color.accent())

        }
       .onTapGesture {
          withAnimation(.easeInOut) {
            showTitle.toggle()
          }
        }

    }
}

public struct ShopMapView: View {
    var shop: ShopInfoProvider
    @EnvironmentObject var model: ShopViewModel

    // 50,73448° N, 7,07530° O
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50.73448, longitude: 7.07530), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    @ViewBuilder
    var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: [ShopLocation(shop: shop)]) { place in
            MapAnnotation(coordinate: place.shop.location.coordinate) {
                AnnotationView(shopLocation: place)
                    .shadow(color: .gray, radius: 3, x: 2, y: 2)

            }
       }
    }
    
    public var body: some View {
        let userLocation = model.userLocation
        
        mapView
            .onAppear {
                region = MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
            }
    }
}
