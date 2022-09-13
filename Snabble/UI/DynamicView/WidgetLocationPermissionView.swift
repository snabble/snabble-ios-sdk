//
//  WidgetLocationPermissionView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 12.09.22.
//

import Foundation
import SwiftUI
import CoreLocation

public class LocationPermissionViewModel: NSObject, ObservableObject {
    @Published public private(set) var widgets: [Widget] = []

    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    private func update(with status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            widgets = []
        case .notDetermined:
            widgets = [
                WidgetButton(
                    id: "Snabble.LocationPermission.notDetermined",
                    text: "Standort freigeben",
                    foregroundColorSource: "onAccent",
                    backgroundColorSource: "accent"
                )
            ]
        case .denied, .restricted:
            widgets = [
                WidgetButton(
                    id: "Snabble.LocationPermission.denied-restricted",
                    text: "Berechtigung fehlt",
                    foregroundColorSource: "onAccent",
                    backgroundColorSource: "accent"
                )
            ]
        @unknown default:
            widgets = []
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
    
    @ObservedObject var dynamicViewModel: DynamicViewModel
    @ObservedObject var viewModel: LocationPermissionViewModel

    init(widget: Widget, viewModel dynamicViewModel: DynamicViewModel) {
        self.widget = widget
        self.dynamicViewModel = dynamicViewModel
        self.viewModel = LocationPermissionViewModel()
    }
    
    public var body: some View {
        VStack {
            ForEach(viewModel.widgets, id: \.id) { widget in
                if let buttonWidget = widget as? WidgetButton {
                    WidgetButtonView(
                        widget: buttonWidget,
                        viewModel: dynamicViewModel
                    )
                }
            }
        }
    }
}
