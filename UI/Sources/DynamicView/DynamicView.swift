//
//  DashboardWidget.swift
//
//
//  Created by Uwe Tilemann on 30.08.22.
//

import Combine
import SwiftUI

public struct DynamicView: View {
    @Environment(DynamicViewModel.self) private var viewModel
    @State private var refresher: AnyCancellable = UserDefaults.standard
        .publisher(for: \.developerMode)
        .handleEvents(receiveOutput: { _ in
            // @Observable automatically handles change notifications
        })
        .sink { _ in }
        
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
                        WidgetContainer(widgets: viewModel.widgets)
                    }
                    .padding(viewModel.configuration.padding?.edgeInsets ?? .init())
                }
            case .list:
                List {
                    WidgetContainer(widgets: viewModel.widgets)
                }
                .padding(viewModel.configuration.padding?.edgeInsets ?? .init())
                .listStyle(.grouped)
            }
        }
        .onAppear {
            // @Observable automatically handles change notifications
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
