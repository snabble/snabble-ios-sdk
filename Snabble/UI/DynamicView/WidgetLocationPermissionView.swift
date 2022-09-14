//
//  WidgetLocationPermissionView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 12.09.22.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

public class LocationPermissionViewModel: NSObject, ObservableObject {
    @Published public private(set) var widgets: [Widget] = []

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
            widgets = []
            permissionDeniedOrRestricted = false
        case .notDetermined:
            widgets = [
                WidgetButton(
                    id: "Snabble.LocationPermission.notDetermined",
                    text: "Snabble.DynamicView.LocationPermission.notDetermined",
                    foregroundColorSource: "onAccent",
                    backgroundColorSource: "accent"
                )
            ]
            permissionDeniedOrRestricted = false
        case .denied, .restricted:
            widgets = []
            permissionDeniedOrRestricted = true
        @unknown default:
            widgets = []
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

public struct WidgetLocationPermissionView: View {
    let widget: Widget

    @ObservedObject private var viewModel = LocationPermissionViewModel()
    
    public var body: some View {
        VStack {
            ForEach(viewModel.widgets, id: \.id) { widget in
                if let buttonWidget = widget as? WidgetButton {
                    WidgetButtonView(widget: buttonWidget) {
                        viewModel.action(for: $0)
                    }
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.permissionDeniedOrRestricted },
            set: { viewModel.permissionDeniedOrRestricted = $0 }
        )) {
            Alert(
                title: Text(keyed: "Snabble.DynamicView.LocationPermission.MissingPermission.title"),
                message: Text(keyed: "Snabble.DynamicView.LocationPermission.MissingPermission.message"),
                primaryButton:
                        .default(
                            Text(keyed: "Snabble.DynamicView.LocationPermission.openSettings"),
                            action: {
                                viewModel.openSettings()
                            }),
                secondaryButton:
                        .cancel(
                            Text(keyed: "Snabble.DynamicView.LocationPermission.notNow")
                        )
            )
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.reducedAccuracy },
            set: { viewModel.reducedAccuracy = $0 }
        )) {
            Alert(
                title: Text(keyed: "Snabble.DynamicView.LocationPermission.ReducedAccuracy.title"),
                message: Text(keyed: "Snabble.DynamicView.LocationPermission.ReducedAccuracy.message"),
                primaryButton:
                        .default(
                            Text(keyed: "Snabble.DynamicView.LocationPermission.openSettings"),
                            action: {
                                viewModel.openSettings()
                            }),
                secondaryButton:
                        .cancel(
                            Text(keyed: "Snabble.DynamicView.LocationPermission.notNow")
                        )
            )
        }
    }
}
