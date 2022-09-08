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
                        WidgetImageView(widget: widget, viewModel: viewModel)
                    }
                case .text:
                    if let widget = widget as? WidgetText {
                        WidgetTextView(widget: widget, viewModel: viewModel)
                    }
                case .button:
                    if let widget = widget as? WidgetButton {
                        WidgetButtonView(widget: widget, viewModel: viewModel)
                    }
                case .information:
                    if let widget = widget as? WidgetInformation {
                        WidgetInformationView(widget: widget, viewModel: viewModel)
                    }
                case .purchases:
                    if let widget = widget as? WidgetPurchase {
                        WidgetPurchaseView(
                            widget: widget,
                            publisher: viewModel.actionPublisher
                        )
                    }
                case .toggle:
                    if let widget = widget as? WidgetToggle {
                        WidgetToggleView(widget: widget, viewModel: viewModel)
                    }
                case .section:
                    EmptyView()
                }
                if let spacing = viewModel.spacing(for: widget) {
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
