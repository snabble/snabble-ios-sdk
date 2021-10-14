//
//  CheckInManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.10.21.
//

import Foundation
import CoreLocation

public protocol CheckInManagerDelegate: AnyObject {
    func checkInManager(_ checkInManager: CheckInManager, willCheckOutOf shop: Shop)
    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop)
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
        willSet {
            if let shop = shop {
                checkInAt = nil
                delegate?.checkInManager(self, willCheckOutOf: shop)
            }
        }
        didSet {
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
    public static var checkInRadius: CLLocationDistance {
        300
    }
    /// 600m
    public static var checkOutRadius: CLLocationDistance {
        600
    }
    /// 15min until automatic checkout occurs
    public static var lastSeenTreshold: TimeInterval {
        900
    }

    public func startUpdating() throws {
        try startUpdating(with: locationManager)
    }

    /// Checks Permissions and throws error if cannot start updating
    func startUpdating(with locationManager: CLLocationManager) throws {
        switch (locationManager.satisfyAccuracyAuthorization, locationManager.satisfyAuthorizationStatus) {
        case (true, true):
            locationManager.startUpdatingLocation()
        case (false, _):
            locationManager.stopUpdatingLocation()
            throw Error.accuracyNotSatisified
        case (_, false):
            locationManager.stopUpdatingLocation()
            throw Error.authorizationNotGranted
        }
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
        try? startUpdating(with: locationManager)
    }

    private var allShops: [Shop] {
        projects.flatMap { $0.shops }
    }

    private let locationManager: CLLocationManager
}

extension CheckInManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        try? startUpdating(with: manager)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        update(with: locations.last)
    }

    private func update(with location: CLLocation?) {
        guard let location = location, location.isValid else { return }

        let checkOutShops = allShops.shops(at: location, in: Self.checkOutRadius)
        let checkInShops = allShops.shops(at: location, in: Self.checkInRadius)

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
        Date.timeIntervalSinceReferenceDate - (checkInAt?.timeIntervalSinceReferenceDate ?? 0) > Self.lastSeenTreshold
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
    var isValid: Bool {
        guard timestamp.timeIntervalSinceNow > -60, // 1 Minute
              horizontalAccuracy >= 0, // negative number invalidates the location
              horizontalAccuracy <= CheckInManager.checkInRadius
        else {
            return false
        }
        return true
    }
}

private extension CLLocationManager {
    var satisfyAccuracyAuthorization: Bool {
        if #available(iOS 14.0, *) {
            switch accuracyAuthorization {
            case .reducedAccuracy:
                return false
            case .fullAccuracy:
                return true
            @unknown default:
                return false
            }
        } else {
            return true
        }
    }

    var satisfyAuthorizationStatus: Bool {
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = self.authorizationStatus
        } else {
            authorizationStatus = Self.authorizationStatus()
        }
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined, .denied, .restricted:
            return false
        @unknown default:
            return false
        }
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
