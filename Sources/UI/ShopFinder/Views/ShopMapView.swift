//
//  ShopMapView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.08.22.
//

import Foundation
import SwiftUI
import MapKit
import Contacts

struct ShopLocation: Swift.Identifiable {
    var id = UUID()
    
    let shop: ShopProviding
}

extension View {
    func navigateToShopAlert(isPresented: Binding<Bool>, shop: ShopProviding) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(title: Text(keyed: "Snabble.Shop.Detail.startNavigation"),
                  message: Text("\(shop.street)\n\(shop.postalCode) \(shop.city)"),
                  primaryButton: .destructive(Text(keyed: "Snabble.yes")) {
                navigate(to: shop)
            },
                  secondaryButton: .cancel())
        }
    }

    private func navigate(to shop: ShopProviding) {
        let endingItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(shop.latitude, shop.longitude),
                                                          addressDictionary: [
                                                            CNPostalAddressCityKey: shop.city,
                                                            CNPostalAddressStreetKey: shop.street,
                                                            CNPostalAddressPostalCodeKey: shop.postalCode,
                                                            CNPostalAddressISOCountryCodeKey: shop.country
                                                          ]))
        endingItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

public struct ShopAnnotationView: View {
    var shopLocation: ShopLocation
    @State private var showTitle = true
    @State private var showingAlert = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @ViewBuilder
    var mapMarker: some View {
        if let image: SwiftUI.Image = Asset.image(named: "Snabble.Shop.Detail.mapPin" ) {
            image
        } else {
            Asset.image(named: "mappin.and.ellipse")
                .foregroundColor(.accent())
                .font(.title)
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
                            .foregroundColor(.onAccent())
                            .cornerRadius(4)
                   }
                    .navigateToShopAlert(isPresented: $showingAlert, shop: shopLocation.shop)

                    VStack(alignment: .leading, spacing: 0) {
                        AddressView(provider: shopLocation.shop)
                    }
                    .foregroundColor(.primary)
                }
                .padding([.leading, .top, .bottom], 4)
                .padding(.trailing, 8)
                .background(Color.systemBackground)
                .cornerRadius(8)
                
                Asset.image(named: "arrowtriangle.down.fill")
                    .foregroundColor(.systemBackground)
            }
            .compositingGroup()
            .opacity(showTitle ? 0 : 1)

            mapMarker
        }
        .onTapGesture {
          withAnimation(.easeInOut) {
            showTitle.toggle()
          }
        }

    }
}

public struct ShopMapView: View {
    let shop: ShopProviding
    let userLocation: CLLocation?

    enum Mode {
        case shop
        case user
    }

    @State private var mode: Mode = .shop
    private var region: MKCoordinateRegion {
        switch mode {
        case .user:
            return userLocation?.region ?? MKCoordinateRegion.region(for: shop)
        case .shop:
            return MKCoordinateRegion.region(for: shop)
        }
    }

    @ViewBuilder
    var mapView: some View {
        Map(coordinateRegion: .init(get: { region }, set: { _ in }),
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: .constant(.none),
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
                mode = .shop
            }) {
                Asset.image(named: mode == .shop ? "house.fill" : "house")
            }
            Button(action: {
                mode = .user
            }) {
                Asset.image(named: mode == .user ? "location.fill" : "location")
            }
        }
        .padding(10)
        .background(Color.systemBackground)
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
    }
}

private extension CLLocation {
    var region: MKCoordinateRegion? {
        MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}

private extension MKCoordinateRegion {
    static func region(for shop: ShopProviding) -> MKCoordinateRegion {
        MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}
