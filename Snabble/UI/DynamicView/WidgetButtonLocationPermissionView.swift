//
//  WidgetButtonLocationPermissionView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 12.09.22.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

public class LocationPermissionViewModel: NSObject, ObservableObject {
    @Published public private(set) var widget: WidgetButton?

    @Published public var permissionDeniedOrRestricted: Bool = false
    @Published public var reducedAccuracy: Bool = false

    let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    private func update(with authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            widget = nil
            permissionDeniedOrRestricted = false
        case .notDetermined:
            widget = WidgetButton(
                id: "Snabble.LocationPermission.notDetermined",
                text: "Snabble.DynamicView.Button.LocationPermission.notDetermined",
                foregroundColorSource: "onAccent",
                backgroundColorSource: "accent"
            )
            permissionDeniedOrRestricted = false
        case .denied, .restricted:
            widget = nil
            permissionDeniedOrRestricted = true
        @unknown default:
            widget = nil
            permissionDeniedOrRestricted = false
        }
    }

    private func update(with accuracyAuthorization: CLAccuracyAuthorization) {
        switch accuracyAuthorization {
        case .reducedAccuracy:
            reducedAccuracy = true
        case .fullAccuracy:
            reducedAccuracy = false
        @unknown default:
            reducedAccuracy = false
        }
    }

    func action(for widget: WidgetButton) {
        switch widget.id {
        case "Snabble.LocationPermission.notDetermined":
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func openSettings() {
        let application = UIApplication.shared
        if let url = URL(string: UIApplication.openSettingsURLString), application.canOpenURL(url) {
            application.open(url)
        }
    }
}

extension LocationPermissionViewModel: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        update(with: status)
        update(with: manager.accuracyAuthorization)
    }
}

public struct WidgetButtonLocationPermissionView: View {
    @ObservedObject private var viewModel: LocationPermissionViewModel

    init(viewModel: LocationPermissionViewModel = .init()) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        if let widget = viewModel.widget {
            WidgetButtonView(widget: widget) {
                viewModel.action(for: $0)
            }
            .alert(isPresented: $viewModel.permissionDeniedOrRestricted) {
                Alert(
                    title: Text(keyed: "Snabble.DynamicView.Button.LocationPermission.MissingPermission.title"),
                    message: Text(keyed: "Snabble.DynamicView.Button.LocationPermission.MissingPermission.message"),
                    primaryButton:
                            .default(
                                Text(keyed: "Snabble.DynamicView.Button.LocationPermission.openSettings"),
                                action: {
                                    viewModel.openSettings()
                                }),
                    secondaryButton:
                            .cancel(
                                Text(keyed: "Snabble.DynamicView.Button.LocationPermission.notNow")
                            )
                )
            }
            .alert(isPresented: $viewModel.reducedAccuracy) {
                Alert(
                    title: Text(keyed: "Snabble.DynamicView.Button.LocationPermission.ReducedAccuracy.title"),
                    message: Text(keyed: "Snabble.DynamicView.Button.LocationPermission.ReducedAccuracy.message"),
                    primaryButton:
                            .default(
                                Text(keyed: "Snabble.DynamicView.Button.LocationPermission.openSettings"),
                                action: {
                                    viewModel.openSettings()
                                }),
                    secondaryButton:
                            .cancel(
                                Text(keyed: "Snabble.DynamicView.Button.LocationPermission.notNow")
                            )
                )
            }
        }
    }
}
