//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
//

import SwiftUI

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
                    ForEach(viewModel.widgets, id: \.id) { widget in
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
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding([.leading, .trailing], 30)
            }
            .padding(.top, 80)
        }
        .edgesIgnoringSafeArea(.all)
    }

}
