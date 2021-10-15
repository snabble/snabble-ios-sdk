//
//  CheckInManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.10.21.
//

import Foundation
import CoreLocation

public protocol CheckInManagerDelegate: AnyObject {
    func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop)
    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop)

    func checkInManager(_ checkInManager: CheckInManager, locationAuthorizationNotGranted authorizationStatus: CLAuthorizationStatus)
    func checkInManager(_ checkInManager: CheckInManager, locationAccuracyNotSufficient accuracyAuthorization: CLAccuracyAuthorization)

    func checkInManager(_ checkInManager: CheckInManager, didFailWithError error: Error)
}

public class CheckInManager: NSObject {
    public static let shared = CheckInManager(projects: SnabbleAPI.projects)

    enum Error: Swift.Error {
        case authorizationNotGranted
        case accuracyNotSatisified
    }

    public var projects: [Project] {
        didSet {
            update(with: locationManager.location)
        }
    }

    public var project: Project? {
        projects.first(where: { $0.id == shop?.projectId })
    }

    /// settable to overwrite our shop
    public var shop: Shop? {
        didSet {
            if let shop = oldValue {
                checkInAt = nil
                delegate?.checkInManager(self, didCheckOutOf: shop)
            }
            if let shop = shop {
                checkInAt = Date()
                delegate?.checkInManager(self, didCheckInTo: shop)
            }
        }
    }

    public private(set) var checkInAt: Date?

    /// available shops sorted by distance
    public private(set) var shops: [Shop] = [] {
        didSet {
            if shop == nil {
                shop = shops.first
            }
        }
    }

    /// CheckInManagerDelegate
    public weak var delegate: CheckInManagerDelegate?

    /// 300m
    public var checkInRadius: CLLocationDistance = 300
    /// 600m
    public var checkOutRadius: CLLocationDistance = 600
    /// 15min until automatic checkout occurs
    public var lastSeenTreshold: TimeInterval = 900

    public func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    /// stops shop updates
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    public init(projects: [Project]) {
        self.projects = projects

        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone

        super.init()

        locationManager.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackgroundNotification(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: UIApplication.shared
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundNotification(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: UIApplication.shared
        )
    }

    @objc private func didEnterBackgroundNotification(_ notification: Notification) {
        locationManager.stopUpdatingLocation()
    }

    @objc private func willEnterForegroundNotification(_ notification: Notification) {
        locationManager.startUpdatingLocation()
    }

    private var allShops: [Shop] {
        projects.flatMap { $0.shops }
    }

    private let locationManager: CLLocationManager
}

extension CheckInManager: CLLocationManagerDelegate {
    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted, .notDetermined:
            manager.stopUpdatingLocation()
            delegate?.checkInManager(self, locationAuthorizationNotGranted: manager.authorizationStatus)
        @unknown default:
            break
        }

        switch manager.accuracyAuthorization {
        case .reducedAccuracy:
            delegate?.checkInManager(self, locationAccuracyNotSufficient: manager.accuracyAuthorization)
        case .fullAccuracy:
            break
        @unknown default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted, .notDetermined:
            manager.stopUpdatingLocation()
            delegate?.checkInManager(self, locationAuthorizationNotGranted: status)
        @unknown default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        update(with: locations.last)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        if let error = error as? CLError, error.code == .denied {
            manager.stopUpdatingLocation()
        }
        delegate?.checkInManager(self, didFailWithError: error)
    }

    private func update(with location: CLLocation?) {
        guard let location = location, location.isValid(inRadius: checkInRadius) else { return }

        let checkOutShops = allShops.shops(at: location, in: checkOutRadius)
        let checkInShops = allShops.shops(at: location, in: checkInRadius)

        if let shop = shop, checkOutShops.contains(shop) {
            checkInAt = Date()
        } else if !checkInShops.isEmpty {
            shop = checkInShops.first
        } else if shop != nil, isInvalidCheckIn(at: checkInAt) {
            shop = nil
        }

        shops = checkInShops
    }

    private func isInvalidCheckIn(at checkInAt: Date?) -> Bool {
        Date.timeIntervalSinceReferenceDate - (checkInAt?.timeIntervalSinceReferenceDate ?? 0) > lastSeenTreshold
    }
}

private extension Array where Element == Shop {
    func shops(at location: CLLocation, in radius: CGFloat) -> [Element] {
        return self
            .filter { $0.distance(to: location) <= radius }
            .sorted { $0.distance(to: location) < $1.distance(to: location) }
    }
}

private extension CLLocation {
    func isValid(inRadius radius: CGFloat) -> Bool {
        guard timestamp.timeIntervalSinceNow > -60, // 1 Minute
              horizontalAccuracy >= 0, // negative number invalidates the location
              horizontalAccuracy <= radius
        else {
            return false
        }
        return true
    }
}

private extension Shop {
    /// convenience accessor for the shop's location
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// get distance from `location`, in meters
    func distance(to location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }
}
