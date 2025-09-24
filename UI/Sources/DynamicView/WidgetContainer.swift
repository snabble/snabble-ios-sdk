//
//  WidgetContainer.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetView: View {
    public var widget: Widget
    @Environment(DynamicViewModel.self) private var viewModel

    public var body: some View {
        if widget.type == .section, let widget = widget as? WidgetSection {
            WidgetSectionView(widget: widget)
        } else if widget.type == .developerMode, let widget = widget as? WidgetDeveloperMode {
            WidgetDeveloperModeView(widget: widget)
       } else {
            Group {
                switch widget.type {
                case .image:
                    image
                case .text:
                    text
                case .button:
                    button
                case .information:
                    information
                case .toggle:
                    toggle
                case .lastPurchases:
                    lastPurchases
                case .navigation:
                    navigation
                case .version:
                    version
                case .locationPermission:
                    locationPermission
                case .allStores:
                    allStores
                case .startShopping:
                    startShopping
                case .connectWifi:
                    connectWifi
                case .customerCard:
                    customerCard
                case .developerMode:
                    EmptyView()
                case .section:
                    EmptyView()
                case .multiValue:
                    multiValue
                }
            }
            .padding(widget.padding?.edgeInsets ?? .init())
        }
    }

    @ViewBuilder
    var image: some View {
        if let widget = widget as? WidgetImage {
            WidgetImageView(
                widget: widget
            )
            .onTapGesture {
                viewModel.actionPublisher.send(.init(widget: widget))
            }
        }
    }

    @ViewBuilder
    var text: some View {
        if let widget = widget as? WidgetText {
            WidgetTextView(
                widget: widget
            )
            .onTapGesture {
                viewModel.actionPublisher.send(.init(widget: widget))
            }
        }
    }

    @ViewBuilder
    var button: some View {
        if let widget = widget as? WidgetButton {
            WidgetButtonView(
                widget: widget,
                action: { widget in
                    viewModel.actionPublisher.send(.init(widget: widget))
                }
            )
        }
    }

    @ViewBuilder
    var information: some View {
        if let widget = widget as? WidgetInformation {
            WidgetInformationView(
                widget: widget,
                configuration: viewModel.configuration
            )
            .onTapGesture {
                viewModel.actionPublisher.send(.init(widget: widget))
            }
        }
    }

    @ViewBuilder
    var toggle: some View {
        if let widget = widget as? WidgetToggle {
            WidgetToggleView(
                widget: widget,
                action: { action in
                    viewModel.actionPublisher.send(action)
                }
            )
        }
    }

    @ViewBuilder
    var lastPurchases: some View {
        if let widget = widget as? WidgetLastPurchases {
            WidgetLastPurchasesView(
                widget: widget,
                configuration: viewModel.configuration,
                action: { action in
                    viewModel.actionPublisher.send(action)
                }
            )
        }
    }
    
    @ViewBuilder
    var navigation: some View {
        if let widget = widget as? WidgetNavigation {
            WidgetNavigationView(widget: widget) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var version: some View {
        if let widget = widget as? WidgetVersion {
            WidgetVersionView(widget: widget) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }
    
    @ViewBuilder
    var locationPermission: some View {
        if let widget = widget as? WidgetLocationPermission {
            WidgetLocationPermissionView(widget: widget) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var allStores: some View {
        if let widget = widget as? WidgetAllStores {
            WidgetAllStoresView(widget: widget) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var startShopping: some View {
        if let widget = widget as? WidgetStartShopping {
            WidgetStartShoppingView(widget: widget) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var connectWifi: some View {
        if let widget = widget as? WidgetConnectWifi {
            WidgetConnectWifiView(
                    widget: widget,
                    configuration: viewModel.configuration
            ) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var customerCard: some View {
        if let widget = widget as? WidgetCustomerCard {
            WidgetCustomerCardView(
                widget: widget,
                configuration: viewModel.configuration
            ) {
                viewModel.actionPublisher.send(.init(widget: $0))
            }
        }
    }

    @ViewBuilder
    var multiValue: some View {
        if let widget = widget as? WidgetMultiValue {
            WidgetMultiValueView(widget: widget, action: { action in
                viewModel.actionPublisher.send(action)
            })
        }
    }
}

public struct WidgetContainer: View {
    @Environment(DynamicViewModel.self) private var viewModel
    public let widgets: [Widget]

    public init(widgets: [Widget]) {
        self.widgets = widgets
    }
    
    public var body: some View {
        ForEach(widgets, id: \.id) { widget in
            WidgetView(widget: widget)
        }
    }
}
