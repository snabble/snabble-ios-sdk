//
//  CheckInManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.10.21.
//

import Foundation
import CoreLocation
import Combine

public protocol CheckInManagerDelegate: AnyObject {
    /// Tells the delegate when the manager did check out of a shop.
    func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop)

    /// Tells the delegate when the manager did check in at a shop.
    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop)

    /// Tells the delegate when the manager cannot start updating locations due to a lack of authorization
    func checkInManager(_ checkInManager: CheckInManager, locationAuthorizationNotGranted authorizationStatus: CLAuthorizationStatus)

    /// Tells the delegate when the manager is unable to check in a shop due to lack of accuracy
    func checkInManager(_ checkInManager: CheckInManager, locationAccuracyNotSufficient accuracyAuthorization: CLAccuracyAuthorization)

    /// Tells the delegate when the manager received `CLLocationManager` errors
    func checkInManager(_ checkInManager: CheckInManager, didFailWithError error: Error)
}

public class CheckInManager: NSObject {
    /// Projects used to find available shops.
    public var projects: [Project] {
        Snabble.shared.projects
    }

    /// Current checked in `Shop`
    public var shop: Shop? {
        didSet {
            shopPublisher.send(shop)
            if let shop = oldValue {
                checkedInAt = nil
                delegate?.checkInManager(self, didCheckOutOf: shop)
            }
            if let shop = shop {
                trackCheckIn(with: shop)
                checkedInAt = Date()
                delegate?.checkInManager(self, didCheckInTo: shop)
            }
        }
    }

    public var shopPublisher = CurrentValueSubject<Shop?, Never>(nil)

    private func trackCheckIn(with shop: Shop) {
        guard let location = locationManager.location, let project = shop.project else { return }
        AppEvent(key: "Check in distance to shop", value: "\(shop.id.rawValue);\(shop.distance(to: location))m", project: project, shopId: shop.id).post()
    }

    /// Latest checked in `Date`. Returns to `nil` if `shop` is `nil`.
    public private(set) var checkedInAt: Date?

    /// Shops available for check-in sorted by distance to your currenct location
    public private(set) var shops: [Shop] = [] {
        didSet {
            if shop == nil {
                shop = shops.first
            }
        }
    }

    /// The delegate object to receive update events.
    public weak var delegate: CheckInManagerDelegate?

    /// Radius which needs to be satisifed to automatically check-in a `shop`
    ///
    /// If a shop stays within the radius, `checkedInAt` continually updates.
    public var checkInRadius: CLLocationDistance = 300

    /// Radius which keeps the `shop` checked-in.
    public var checkOutRadius: CLLocationDistance = 600

    /// Threshold which keeps a `shop` checked in if it's outside of the `checkOutRadius`.
    ///
    /// It only applies if no shop is currently within the `checkInRadius`.
    public var lastSeenThreshold: TimeInterval = 900

    /// Starts updating location to determine available shops
    public func startUpdating() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        isUpdating = true
    }

    /// Stops updating locations
    ///
    /// Current `shop` will not automatically check out.
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
        isUpdating = false
    }

    /// Shows if updating is activated
    public private(set) var isUpdating = false

    public let locationManager: CLLocationManager

    override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataLoadedNotification(_:)),
            name: .metadataLoaded,
            object: nil
        )
    }

    @objc private func metadataLoadedNotification(_ notification: Notification) {
        if isUpdating {
            update(with: locationManager.location)
        }
    }
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
            return
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

        let allShops = projects.flatMap { $0.shops }
        let checkOutShops = allShops.shops(at: location, in: checkOutRadius)
        let checkInShops = allShops.shops(at: location, in: checkInRadius)

        if let currentShop = shop, !checkInShops.contains(currentShop), !checkInShops.isEmpty {
            shop = checkInShops.first
        } else if let shop = shop, checkOutShops.contains(shop) {
            checkedInAt = Date()
        } else if !checkInShops.isEmpty {
            shop = checkInShops.first
        } else if shop != nil, isInvalidCheckIn(at: checkedInAt) {
            shop = nil
        }

        shops = checkInShops
    }

    private func isInvalidCheckIn(at checkInAt: Date?) -> Bool {
        Date.timeIntervalSinceReferenceDate - (checkInAt?.timeIntervalSinceReferenceDate ?? 0) > lastSeenThreshold
    }
}

private extension Array where Element == Shop {
    func shops(at location: CLLocation, in radius: CGFloat) -> [Element] {
        return self
            .filter { $0.distance(to: location) < radius }
            .sorted { $0.distance(to: location) < $1.distance(to: location) }
    }
}

private extension CLLocation {
    func isValid(inRadius radius: CGFloat) -> Bool {
        guard timestamp.timeIntervalSinceNow > -60, // 1 Minute
              horizontalAccuracy >= 0, // negative number invalidates the location
              horizontalAccuracy < radius
        else {
            return false
        }
        return true
    }
}

public extension Shop {
    /// convenience accessor for the shop's location
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// get distance from `location`, in meters
    func distance(to location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }
}
