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
import SnabbleAssetProviding
import SnabbleComponents

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

public struct ShopMapView: View {
    @SwiftUI.Environment(\.project) private var project
    
    let shop: ShopProviding
    let showNavigationControl: Bool

    enum Mode {
        case shop
        case user
    }

    public init(shop: ShopProviding, showNavigationControl: Bool = false) {
        self.shop = shop
        self.showNavigationControl = showNavigationControl
    }
    
    @State private var mode: Mode = .shop {
        didSet {
            updatePosition(forMode: mode)
        }
    }
    
    @State private var showingAlert: Bool = false
    @State private var showingDetails: Bool = false
    
    @State private var position: MapCameraPosition = .automatic
    
    private func updatePosition(forMode mode: Mode) {
        switch mode {
        case .user:
            position = .userLocation(fallback: .region(.region(for: shop)))
        case .shop:
            position = .region(.region(for: shop))
        }
    }
    
    @ViewBuilder
    var shopAnnotation: some View {
        Group {
            if let image: SwiftUI.Image = Asset.image(named: "Snabble.Shop.Detail.mapPin" ) {
                image
            } else {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.projectPrimary())
                    .font(.title)
            }
        }.onTapGesture {
            showingDetails.toggle()
        }
    }
    
    @ViewBuilder
    var mapView: some View {
        Map(position: $position) {
            Annotation("", coordinate: shop.location.coordinate, anchor: .bottom) {
                VStack(spacing: -2) {
                    HStack {
                        Button(action: {
                            showingAlert.toggle()
                        }) {
                            Image(systemName: "car.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .background(Color.projectPrimary())
                                .foregroundColor(.onProjectPrimary())
                                .cornerRadius(4)
                        }
                        .navigateToShopAlert(isPresented: $showingAlert, shop: shop)

                        VStack(alignment: .leading, spacing: 0) {
                            AddressView(provider: shop)
                        }
                        .foregroundColor(.primary)
                    }
                    .padding([.leading, .top, .bottom], 4)
                    .padding(.trailing, 8)
                    .background(Color.systemBackground)
                    .cornerRadius(8)
                    .onTapGesture {
                        showingDetails.toggle()
                    }
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundColor(.systemBackground)
                    
                    Spacer(minLength: 16)
                }
                .compositingGroup()
                .opacity(showingDetails ? 1 : 0)
            }
            .annotationTitles(.hidden)
            .annotationSubtitles(.hidden)
            Annotation(shop.name, coordinate: shop.location.coordinate) {
                shopAnnotation
            }
            UserAnnotation()
        }
        .task {
            updatePosition(forMode: mode)
        }
    }

    @ViewBuilder
    var locationControl: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    mode = .shop
                }
            }) {
                Image(systemName: mode == .shop ? "house.fill" : "house")
            }

            Button(action: {
                withAnimation {
                    mode = .user
                }
            }) {
                Image(systemName: mode == .user ? "location.fill" : "location")
            }

            if showNavigationControl {
                Button(action: {
                    showingAlert.toggle()
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                }
                .navigateToShopAlert(isPresented: $showingAlert, shop: shop)
            }
        }
        .padding(10)
        .background(Color.systemBackground)
        .foregroundColor(Color.projectPrimary())
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

private extension MKCoordinateRegion {
    static func region(for shop: ShopProviding) -> MKCoordinateRegion {
        MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}
