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
    
    @State var projectId: Identifier<Project>
    
    init(widget: WidgetLastPurchases, configuration: DynamicViewConfiguration, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.configuration = configuration
        self.action = action
        self.projectId = widget.projectId
    }
    
    public var body: some View {
        AsyncScreen(id: projectId) { projectId in
            await load(projectId: projectId)
        }
        success: { output in
            if output.isEmpty {
                EmptyView()
            } else {
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
        }
    }
    
    private func load(projectId: Identifier<Project>) async -> [PurchaseProviding] {
        guard let project = Snabble.shared.project(for: projectId) else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            OrderList.load(project) { result in
                do {
                    let providers = try result.get().receipts
                    continuation.resume(returning: providers)
                } catch {
                    continuation.resume(returning: [])
                }
            }
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
                if let amount = provider.amount {
                    Text(amount)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
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
