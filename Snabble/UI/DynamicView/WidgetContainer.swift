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
                    if let widget = widget as? WidgetImage {
                        WidgetImageView(
                            widget: widget
                        )
                        .onTapGesture {
                            viewModel.actionPublisher.send(.init(widget: widget))
                        }
                    }
                case .text:
                    if let widget = widget as? WidgetText {
                        WidgetTextView(
                            widget: widget
                        )
                        .onTapGesture {
                            viewModel.actionPublisher.send(.init(widget: widget))
                        }
                    }
                case .button:
                    if let widget = widget as? WidgetButton {
                        WidgetButtonView(
                            widget: widget
                        ) {
                            viewModel.actionPublisher.send(.init(widget: $0))
                        }
                    }
                case .connectWifi:
                    if let widget = widget as? WidgetConnectWifi {
                        WidgetConnectWifiView(widget: widget, viewModel: viewModel)
                    }
                case .information:
                    if let widget = widget as? WidgetInformation {
                        WidgetInformationView(
                            widget: widget,
                            shadowRadius: viewModel.configuration.shadowRadius
                        )
                        .onTapGesture {
                            viewModel.actionPublisher.send(.init(widget: widget))
                        }
                    }
                case .purchases:
                    if let widget = widget as? WidgetPurchase {
                        WidgetPurchasesView(
                            widget: widget,
                            shadowRadius: viewModel.configuration.shadowRadius,
                            action: {
                                viewModel.actionPublisher.send($0)
                            }
                        )
                    }
                case .toggle:
                    if let widget = widget as? WidgetToggle {
                        WidgetToggleView(
                            widget: widget,
                            action: {
                                viewModel.actionPublisher.send($0)
                            }
                        )
                    }
                case .section, .locationPermission:
                    EmptyView()
                }
                if let spacing = widget.spacing ?? viewModel.configuration.spacing {
                    Spacer(minLength: spacing)
                }
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
