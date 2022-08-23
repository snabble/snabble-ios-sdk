//
//  ShopViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import Contacts

// stuff for displaying formatted numbers
extension Double {
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

/// ShopViewModel for objects implermenting the ShopInfoProvider protocol
public final class ShopViewModel: NSObject, ObservableObject {
    public static let `default` = ShopViewModel()

    @Published public var shops: [ShopInfoProvider] = []

    private let locationManager = CLLocationManager()
    
    private var distances = [String: Double]()  // shop.id -> distance

    @Published var distancesAvailable = false

    public var userLocation: CLLocation?
    
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

extension ShopViewModel: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        if status == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.stopUpdatingLocation()
            self.distances.removeAll()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        userLocation = location
        
        self.shops.forEach {
            self.distances[$0.id] = $0.distance(to: location)
        }
        self.distancesAvailable = true
        
        locationManager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            if error.code != .locationUnknown {
                print("locationDidFail: \(error)")
            }

            if error.code == .denied {
                manager.requestAlwaysAuthorization()
                self.distancesAvailable = false
            }
        }
    }
}

extension ShopViewModel {
    var userRegion: MKCoordinateRegion? {
        guard let location = userLocation else {
            return nil
        }
        return MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }

    func region(for shop: ShopInfoProvider) -> MKCoordinateRegion {
        MKCoordinateRegion(center: shop.location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    }
}

extension ShopViewModel {
    func navigate(to shop: ShopInfoProvider) {
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
