//
//  UIAlertController+LocationPermissions.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 13.09.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleSDK
import CoreLocation

extension CLLocationManager {
    func requestLocationPermission(on viewController: UIViewController) {
        switch (accuracyAuthorization, authorizationStatus) {
        case (_, .notDetermined):
            requestWhenInUseAuthorization()
        case (_, .denied), (_, .restricted):
            viewController.present(UIAlertController.missingLocationPermission(), animated: true)
        case (.reducedAccuracy, _):
            viewController.present(UIAlertController.locationAccuracyReduced(), animated: true)
        default:
            viewController.present(UIAlertController.missingLocationPermission(), animated: true)
        }
    }
}

private extension UIAlertAction {
    static func cancel(withHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        .init(title: Asset.localizedString(forKey: "Snabble.LocationRequired.notNow"), style: .cancel, handler: handler)
    }

    static var settings: UIAlertAction {
        .init(title: Asset.localizedString(forKey: "Snabble.LocationRequired.openSettings"), style: .default) { _ in
            let application = UIApplication.shared
            if let url = URL(string: UIApplication.openSettingsURLString), application.canOpenURL(url) {
                application.open(url)
            }
        }
    }
}
extension UIAlertController {
    static func missingLocationPermission() -> UIAlertController {
        alertController(title: Asset.localizedString(forKey: "Snabble.LocationRequired.MissingPermission.title"),
                        message: Asset.localizedString(forKey: "Snabble.LocationRequired.MissingPermission.message"))
    }

    static func locationAccuracyReduced() -> UIAlertController {
        alertController(title: Asset.localizedString(forKey: "Snabble.LocationRequired.ReducedAccuracy.title"),
                        message: Asset.localizedString(forKey: "Snabble.LocationRequired.ReducedAccuracy.message"))
    }

    private static func alertController(title: String, message: String, cancelHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction.settings)
        alertController.addAction(UIAlertAction.cancel(withHandler: handler))

        return alertController
    }
}
