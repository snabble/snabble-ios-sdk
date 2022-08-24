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

extension View {
    func navigateToShopAlert(isPresented: Binding<Bool>, shop: ShopInfoProvider) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(title: Text(key: "Snabble.Shop.Detail.startNavigation"),
                  message: Text("\(shop.street)\n\(shop.postalCode) \(shop.city)"),
                  primaryButton: .destructive(Text(key: "Snabble.yes")) {
                ShopsViewModel.navigate(to: shop)
            },
                  secondaryButton: .cancel())
        }
    }
}

public struct ShopAnnotationView: View {
    var shopLocation: ShopLocation
    @State private var showTitle = true
    @State private var showingAlert = false

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
                        SwiftUI.Image.image(named: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(8)
                            .background(Color.accent())
                            .foregroundColor(.white)
                            .cornerRadius(4)
                   }
                    .navigateToShopAlert(isPresented: $showingAlert, shop: shopLocation.shop)

                    VStack(alignment: .leading, spacing: 0) {
                        AddressView(provider: shopLocation.shop)
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
    @ObservedObject var viewModel: ShopsViewModel
    @State var tracking: MapUserTrackingMode = .follow
    
    enum CurrentLocation {
        case shop
        case user
    }
    
    @State private var currentLocation: CurrentLocation = .shop
    @State private var showLocation = false
    // 50,73448° N, 7,07530° O is snabbles home location
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50.73448, longitude: 7.07530), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    @ViewBuilder
    var mapView: some View {
        Map(coordinateRegion: $region,
            interactionModes: MapInteractionModes.all,
            showsUserLocation: true,
            userTrackingMode: $tracking,
            annotationItems: [ShopLocation(shop: shop)]) { place in

            MapAnnotation(coordinate: place.shop.location.coordinate) {
                ShopAnnotationView(shopLocation: place)
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
            region = ShopsViewModel.region(for: shop)
        }
        .onChange(of: showLocation) { _ in
            showLocation = false
            withAnimation(.easeInOut) {
                switch currentLocation {
                case .shop:
                    region = ShopsViewModel.region(for: shop)
                case .user:
                    if let userRegion = viewModel.userRegion {
                        region = userRegion
                        // maybe user is moving so update current location
                        viewModel.startUpdating()
                    }
                }
            }
        }

    }
}
