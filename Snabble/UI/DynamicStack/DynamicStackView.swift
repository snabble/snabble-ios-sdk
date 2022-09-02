//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
//

import SwiftUI

public struct WidgetView: View {
    var widget: Widget
    @ObservedObject var viewModel: DynamicStackViewModel

    public var body: some View {
        VStack(spacing: 0) {
            switch widget.type {
            case .image:
                if let widget = widget as? WidgetImage {
                    WidgetImageView(widget: widget, viewModel: viewModel)
                }
            case .text:
                if let widget = widget as? WidgetText {
                    WidgetTextView(widget: widget)
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
                    WidgetPurchaseView(widget: widget, viewModel: viewModel)
                }
            case .toggle:
                if let widget = widget as? WidgetToggle {
                    WidgetToggleView(widget: widget, viewModel: viewModel)
                }
            case .section:
                if let widget = widget as? WidgetSection {
                    WidgetSectionView(widget: widget, viewModel: viewModel)
                }
            }
            if let spacing = viewModel.spacing(for: widget) {
                Spacer(minLength: spacing)
            }
        }
    }
}

public struct WidgetContainer: View {
    @ObservedObject public var viewModel: DynamicStackViewModel
    let widgets: [Widget]
      
    public var body: some View {
        ForEach(widgets, id: \.id) { widget in
            WidgetView(widget: widget, viewModel: viewModel)
        }
    }
}

public struct DynamicStackView: View {
    @ObservedObject public var viewModel: DynamicStackViewModel

    public init(viewModel: DynamicStackViewModel) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    var teaser: some View {
        if let image = viewModel.configuration.image {
            VStack {
                image
                    .resizable()
                    .scaledToFit()
                Spacer()
            }
        } else {
            EmptyView()
        }
    }

    public var body: some View {
        ZStack {
            teaser
            
            ScrollView(.vertical) {
                VStack(alignment: .center) {
                    WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                }
                .padding([.leading, .trailing], 30)
            }
            .padding(.top, 80)
        }
        .edgesIgnoringSafeArea(.all)
    }

}
