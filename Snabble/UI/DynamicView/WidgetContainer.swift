//
//  WidgetContainer.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetView: View {
    public var widget: Widget
    @ObservedObject var viewModel: DynamicViewModel

    public var body: some View {
        if widget.type == .section, let widget = widget as? WidgetSection {
            WidgetSectionView(widget: widget, viewModel: viewModel)
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
                case .snabble:
                    snabble
                case .section:
                    EmptyView()
                }
                if let spacing = widget.spacing ?? viewModel.configuration.spacing {
                    Spacer(minLength: spacing)
                }
            }
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
                shadowRadius: viewModel.configuration.shadowRadius
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
    var snabble: some View {
        if let widget = widget as? WidgetSnabble {
            switch widget.id {
            case "io.snabble.dynamicView.locationPermission":
                WidgetButtonLocationPermissionView()
            case "io.snabble.dynamicView.lastPurchases":
                WidgetPurchasesView(
                    widget: widget,
                    shadowRadius: viewModel.configuration.shadowRadius,
                    action: { action in
                        viewModel.actionPublisher.send(action)
                    }
                )
            case "io.snabble.dynamicView.startShopping":
                WidgetButtonStartShoppingView(widget: widget) {
                    viewModel.actionPublisher.send(.init(widget: $0))
                }
            case "io.snabble.dynamicView.stores":
                WidgetButtonStoresView(widget: widget) {
                    viewModel.actionPublisher.send(.init(widget: $0))
                }
            default:
                EmptyView()
            }
        }
    }
}

public struct WidgetContainer: View {
    @ObservedObject public var viewModel: DynamicViewModel
    public let widgets: [Widget]
      
    public init(viewModel: DynamicViewModel, widgets: [Widget]) {
        self.viewModel = viewModel
        self.widgets = widgets
    }
    
    public var body: some View {
        ForEach(widgets, id: \.id) { widget in
            WidgetView(widget: widget, viewModel: viewModel)
        }
    }
}
