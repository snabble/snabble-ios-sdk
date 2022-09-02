//
//  DynamicListView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 02.09.22.
//

import SwiftUI

public struct DynamicListView: View {
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
//                NavigationView {
                List {
                    WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                }
                .listStyle(.grouped)
//                }
//                .navigationViewStyle(.stack)
           }

    }
}
