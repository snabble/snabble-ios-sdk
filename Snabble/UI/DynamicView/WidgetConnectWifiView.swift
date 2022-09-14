//
//  WidgetConnectWifiView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 14.09.22.
//

import SwiftUI

public struct WidgetConnectWifiView: View {
    let widget: WidgetConnectWifi
    @ObservedObject var viewModel: DynamicViewModel

    @ViewBuilder
    var image: some View {
        if let image: SwiftUI.Image = Asset.image(named: "Snabble.DynamicView.wifi" ) {
            image
        } else {
            Asset.image(named: "wifi")
                .foregroundColor(.accent())
                .font(.title)
        }
    }

    public var body: some View {
        if widget.isVisible {
            HStack(alignment: .center) {
                Text(keyed: "Snabble.DynamicView.wifi")
                    .font(.subheadline)
                Spacer()
                image
            }
            .informationStyle()
            .onTapGesture {
                viewModel.actionPublisher.send(.init(widget: widget))
            }
            .shadow(radius: viewModel.configuration.shadowRadius)
        } else {
            EmptyView()
        }
    }
}
