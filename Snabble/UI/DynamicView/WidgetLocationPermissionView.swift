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

    let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    private func update(with status: CLAuthorizationStatus) {
        switch status {
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
            widgets = [
                WidgetButton(
                    id: "Snabble.LocationPermission.denied-restricted",
                    text: "Snabble.DynamicView.LocationPermission.denied-restricted",
                    foregroundColorSource: "onAccent",
                    backgroundColorSource: "accent"
                )
            ]
            permissionDeniedOrRestricted = true
        @unknown default:
            widgets = []
            permissionDeniedOrRestricted = false
        }
    }

    func action(for widget: WidgetButton) {
        switch widget.id {
        case "Snabble.LocationPermission.notDetermined":
            locationManager.requestWhenInUseAuthorization()
        case "Snabble.LocationPermission.denied-restricted":
            openSettings()
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
    }
}

public struct WidgetLocationPermissionView: View {
    let widget: Widget

    @ObservedObject var viewModel = LocationPermissionViewModel()

    init(widget: Widget) {
        self.widget = widget
    }
    
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
                title: Text(keyed: "Snabble.LocationRequired.MissingPermission.title"),
                message: Text(keyed: "Snabble.LocationRequired.MissingPermission.message"),
                primaryButton:
                        .default(
                            Text(keyed: "Snabble.LocationRequired.openSettings"),
                            action: {
                                viewModel.openSettings()
                            }),
                secondaryButton:
                        .cancel(
                            Text(keyed: "Snabble.LocationRequired.notNow")
                        )
            )
        }
    }
}
