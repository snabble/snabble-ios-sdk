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
import SnabbleCore

public protocol ShopViewModelDelegate: AnyObject {
    func shopViewModel(_ model: ShopsViewModel, didUpdateDistances: [Identifier<Shop>: Double])
}

/// ShopsViewModel for objects implermenting the ShopProviding protocol
@Observable
public final class ShopsViewModel: NSObject {
    public init(shops: [ShopProviding]) {
        self.shops = shops
        self.distances = [:]
        self.locationManager = CLLocationManager()
        
        super.init()

        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.delegate = self
    }

    /// All available shops
    public private(set) var shops: [ShopProviding]

    /// Current check-in shop
    public var shop: ShopProviding?

    /// distances in meter to a shop by id
    private(set) var distances: [Identifier<Shop>: Double]

    public weak var delegate: ShopViewModelDelegate?
    
    /// Emits if the button on ShopView is tapped
    /// - `Output` is the current visible shop
    public let actionPublisher = PassthroughSubject<ShopProviding, Never>()

    public func distance(from shop: ShopProviding) -> Double? {
        distances[shop.id]
    }

    public func isCurrent(_ shop: ShopProviding) -> Bool {
        guard let currentShop = self.shop else {
            return false
        }
        return currentShop.id == shop.id
    }

    public let locationManager: CLLocationManager

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
        @unknown default:
            distances.removeAll()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        var distances: [Identifier<Shop>: Double] = [:]
        shops.forEach {
            distances[$0.id] = $0.distance(from: location)
        }
        self.distances = distances

        shops = shops.sorted { lhs, rhs in
            lhs.distance(from: location) < rhs.distance(from: location)
        }
        delegate?.shopViewModel(self, didUpdateDistances: self.distances)
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

public protocol ShopProviding: AddressProviding {
    var id: Identifier<Shop> { get }
    var name: String { get }

    var email: String { get }
    var phone: String { get }

    var street: String { get }
    var postalCode: String { get }
    var city: String { get }
    var country: String { get }

    var latitude: Double { get }
    var longitude: Double { get }

    /// opening hours
    var openingHoursSpecification: [OpeningHoursSpecification] { get }
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
