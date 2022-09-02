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
                    WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                }
                .padding([.leading, .trailing], 30)
            }
            .padding(.top, 80)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
