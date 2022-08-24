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
    public init(shops: [ShopInfoProvider]) {
        self.shops = shops
        super.init()
    }

    @Published public var shops: [ShopInfoProvider]

    private let locationManager = CLLocationManager()

    /// distances in meter to an shop by id
    @Published var distances = [String: Double]()

    public var userLocation: CLLocation? {
        locationManager.location
    }

    public func distance(for shop: ShopInfoProvider) -> Double {
        return distances[shop.id] ?? 0
    }
    
    public func formattedDistance(for shop: ShopInfoProvider) -> String {
        guard let value = distances[shop.id] else {
            return ""
        }
        return value.formattedDistance()
    }

    public func startUpdating() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
}

// stuff for displaying formatted numbers
private extension Double {
    /// format a distance value in meters
    func formattedDistance() -> String {
        let value: Double
        let format: String
        if self < 1000 {
            value = self
            format = "#0 m"
        } else if self < 100000.0 {
            value = self / 1000.0
            format = "#0.0 km"
        } else {
            value = self / 1000.0
            format = "#0 km"
        }

        let formatter = NumberFormatter()
        formatter.positiveFormat = format
        return formatter.string(for: value)!
    }
}

extension LocationProviding {
    public var id: String {
        return "\(self.latitude)-\(self.longitude)"
    }
}

extension ShopsViewModel: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted, .notDetermined:
            manager.stopUpdatingLocation()
            distances.removeAll()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        shops.forEach {
            distances[$0.id] = $0.distance(from: location)
        }

        shops = shops.sorted { lhs, rhs in
            lhs.distance(from: location) < rhs.distance(from: location)
        }
        
        manager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            if error.code != .locationUnknown {
                print("locationDidFail: \(error)")
            }

            if error.code == .denied {
                manager.requestAlwaysAuthorization()
            }
        }
    }
}

extension ShopsViewModel {
    var userRegion: MKCoordinateRegion? {
        guard let location = userLocation else {
            return nil
        }
        return MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }

    static func region(for shop: ShopInfoProvider) -> MKCoordinateRegion {
        MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}

extension ShopsViewModel {
    static func navigate(to shop: ShopInfoProvider) {
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

/// Protocol to provide address information
public protocol AddressProviding {
    /// name of an address
    var name: String { get }
    /// street
    var street: String { get }
    /// postal code
    var postalCode: String { get }
    /// city
    var city: String { get }
}

/// Protocol to provide location
public protocol LocationProviding {
    /// latitude
    var latitude: Double { get }
    /// longitude
    var longitude: Double { get }
}

public extension LocationProviding {
    /// convenience accessor for the shop's location
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// get distance from `location`, in meters
    func distance(from location: CLLocation) -> CLLocationDistance {
        location.distance(from: location)
    }
}

/// Protocol to provide country information
public protocol CountryProviding {
    /// state
    var state: String { get }
    /// country
    var country: String { get }
    /// optional country code
    var countryCode: String? { get }
}

/// Protocol to provide communication information
public protocol CommunicationProviding {
    /// email address
    var email: String { get }
    /// phone number
    var phone: String { get }
}

public typealias ShopInfoProvider = AddressProviding & LocationProviding & CountryProviding & CommunicationProviding
