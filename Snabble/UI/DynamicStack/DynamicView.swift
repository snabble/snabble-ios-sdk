//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
//

import SwiftUI

public struct DynamicView: View {
    @ObservedObject public var viewModel: DynamicViewModel

    public init(viewModel: DynamicViewModel) {
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
            teaser.edgesIgnoringSafeArea(.top)
            
            switch viewModel.configuration.stackStyle {
            case .scroll:
                ScrollView(.vertical) {
                    VStack(alignment: .center) {
                        WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                    }
                    .padding([.leading, .trailing], viewModel.configuration.padding ?? 0)
                }
            case .list:
                List {
                    WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                }
                .padding([.leading, .trailing], viewModel.configuration.padding ?? 0)
                .listStyle(.grouped)
            }
        }
        
    }
}
