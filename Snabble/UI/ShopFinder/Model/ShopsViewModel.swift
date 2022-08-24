//
//  ShopsViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import Contacts

/// ShopFinderViewModel for objects implermenting the ShopInfoProvider protocol
public final class ShopsViewModel: NSObject, ObservableObject {
    public init(shops: [ShopProviding]) {
        self.shops = shops
        self.distances = [:]
        self.locationManager = CLLocationManager()
        
        super.init()

        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.delegate = self
    }

    @Published public private(set) var shops: [ShopProviding]

    /// distances in meter to a shop by id
    @Published public private(set) var distances: [String: Double]

    let locationManager: CLLocationManager
    
    public func distance(for shop: ShopProviding) -> Double? {
        distances[shop.id]
    }

    public func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
}

extension ShopsViewModel: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .denied, .restricted, .notDetermined:
            distances.removeAll()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        distances.removeAll()

        shops.forEach { shop in
            distances[shop.id] = shop.distance(from: location)
        }

        shops = shops.sorted { lhs, rhs in
            lhs.distance(from: location) < rhs.distance(from: location)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            if error.code != .locationUnknown {
                print("locationDidFail: \(error)")
            }

            if error.code == .denied {
                manager.requestAlwaysAuthorization()
                distances.removeAll()
            }
        }
    }
}

extension ShopsViewModel {
    var userRegion: MKCoordinateRegion? {
        guard let location = locationManager.location else {
            return nil
        }
        return MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }

    static func region(for shop: ShopProviding) -> MKCoordinateRegion {
        MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}

extension ShopsViewModel {
    static func navigate(to shop: ShopProviding) {
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

public protocol ShopProviding: AddressProviding {
    var name: String { get }

    var email: String { get }
    var phone: String { get }

    var street: String { get }
    var postalCode: String { get }
    var city: String { get }
    var country: String { get }

    var latitude: Double { get }
    var longitude: Double { get }
}

extension ShopProviding {
    public var id: String {
        return "\(latitude)-\(longitude)"
    }
}

public extension ShopProviding {
    /// convenience accessor for the shop's location
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// get distance from `location`, in meters
    func distance(from location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }
}

extension Shop: ShopProviding {}
