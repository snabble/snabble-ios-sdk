//
//  WidgetPurchasesView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI
import Combine
import SnabbleCore

extension Array where Element == PurchaseProviding {
    var title: String {
        return count > 1 ? "Snabble.DynamicView.lastPurchases" : "Snabble.DynamicView.lastPurchase"
    }
}

public struct WidgetLastPurchasesView: View {
    let widget: WidgetLastPurchases
    let configuration: DynamicViewConfiguration
    let action: (DynamicAction) -> Void
    @StateObject var viewModel = LastPurchasesViewModel()
    
    init(widget: WidgetLastPurchases, configuration: DynamicViewConfiguration, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.configuration = configuration
        self.action = action
    }
    
    public var body: some View {
        AsyncContentView(source: viewModel) { output in
            VStack(alignment: .leading) {
                HStack {
                    Text(keyed: output.title)
                    Spacer()
                    Button(action: {
                        action(.init(widget: widget, userInfo: ["action": "more"]))
                    }) {
                        Text(keyed: "Snabble.DynamicView.LastPurchases.all")
                    }
                }
                HStack {
                    ForEach(output.prefix(2), id: \.id) { provider in
                        WidgetOrderView(
                            provider: provider
                        ).onTapGesture {
                            action(.init(widget: widget, userInfo: ["action": "purchase", "id": provider.id]))
                        }
                   }
                }
                .shadow(radius: configuration.shadowRadius)
            }
        }
        .onAppear {
            viewModel.projectId = widget.projectId
            viewModel.load()
        }
    }
}

private struct WidgetOrderView: View {
    let provider: PurchaseProviding

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SwiftUI.Image.image(named: "Snabble.DynamicView.LastPurchases.project", domain: provider.projectId)
                    .resizable()
                    .frame(width: 14, height: 14)
                Spacer()
                Text(provider.amount)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
            Text(provider.name)
                .font(.subheadline)

            Text(provider.time)
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
        }
        .informationStyle()
    }
}
