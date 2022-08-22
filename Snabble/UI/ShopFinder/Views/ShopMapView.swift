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
    @State private var showingAlert = false
    
    @EnvironmentObject var model: ShopViewModel

    @ViewBuilder
    var mapMarker: some View {
        if let image: UIImage = Asset.image(named: "Snabble.Shop.Detail.mapPin") {
            SwiftUI.Image(uiImage: image)
                .padding(1)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Group {
                Asset.image(named: "mappin.and.ellipse")
                    .font(.title)
            }
        }
    }

    public var body: some View {
        VStack {
            VStack(spacing: -2) {
                HStack {
                    Button(action: {
                        showingAlert.toggle()
                    }) {
                        SwiftUI.Image(named: "car.fill", systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(8)
                            .background(Color.accent())
                            .foregroundColor(.white)
                            .cornerRadius(4)
                   }
                    .alert(isPresented: $showingAlert) {
                       Alert(title: Text("Snabble.Shop.Detail.startNavigation"),
                             message: Text("\(shopLocation.shop.street)\n\(shopLocation.shop.postalCode) \(shopLocation.shop.city)"),
                             primaryButton: .destructive(Text("yes")) {
                           model.navigate(to: shopLocation.shop)
                       },
                             secondaryButton: .cancel())
                   }

                    VStack(alignment: .leading, spacing: 0) {
                        ShopAddressView(shop: shopLocation.shop)
                    }
                }
                .padding(5)
                .background(Color(.white))
                .cornerRadius(8)
                
                Asset.image(named: "arrowtriangle.down.fill")
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
    
    enum CurrentLocation {
        case shop
        case user
    }
    @State private var currentLocation: CurrentLocation = .shop
    @State private var showLocation = false
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
    @ViewBuilder
    var locationControl: some View {
        VStack(spacing: 12) {
            Button(action: {
                currentLocation = .shop
                showLocation = true
            }) {
                Asset.image(named: currentLocation == .shop ? "house.fill" : "house")
            }
            Button(action: {
                currentLocation = .user
                showLocation = true
            }) {
                Asset.image(named: currentLocation == .user ? "location.fill" : "location")
            }
        }
        .padding(10)
        .background(Color.white)
        .foregroundColor(Color.accent())
        .cornerRadius(8)
        .shadow(color: .gray, radius: 3, x: 0, y: 0)
    }
    
    public var body: some View {
        
        ZStack(alignment: .topTrailing) {
            mapView
            locationControl
                .padding()
                .zIndex(1)
        }
        .onAppear {
            region = MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        }
        .onChange(of: showLocation) { _ in

            showLocation = false
            withAnimation(.easeInOut) {
                switch currentLocation {
                case .shop:
                    region = MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
                case .user:
                    if let location = model.userLocation {
                        region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
                        model.startUpdating()
                    }
                }
            }
        }

    }
}
