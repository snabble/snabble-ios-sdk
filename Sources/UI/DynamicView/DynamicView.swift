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
                    .padding(viewModel.configuration.padding?.edgeInsets ?? .init())
                }
            case .list:
                List {
                    WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                }
                .padding(viewModel.configuration.padding?.edgeInsets ?? .init())
                .listStyle(.grouped)
            }
        }
        .onAppear {
            viewModel.objectWillChange.send()
        }
    }
}

private extension View {
    func horizontalPadding(_ padding: CGFloat?) -> some View {
        modifier(HorizontalPadding(value: padding))
    }
}

private struct HorizontalPadding: ViewModifier {
    let value: CGFloat?

    func body(content: Content) -> some View {
        content
            .padding([.leading, .trailing], value ?? 0)
    }
}
