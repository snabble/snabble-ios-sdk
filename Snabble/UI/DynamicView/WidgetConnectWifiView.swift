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
        if let image = widget.image {
            image
                .renderingMode(.template)
                .foregroundColor(.accent())
        } else {
            EmptyView()
        }
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            Text(keyed: widget.text)
                .font(.subheadline)
            Spacer()
            image
        }
        .informationStyle()
        .onTapGesture {
            viewModel.actionPublisher.send(.init(widget: widget))
        }
        .shadow(radius: viewModel.configuration.shadowRadius)
    }
}
