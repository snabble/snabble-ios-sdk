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
    public var widgets: [Widget] = []

    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    private func update(with status: CLAuthorizationStatus) {
        print(#function, status.rawValue)
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
        Text("LocationPermission")
    }
}
