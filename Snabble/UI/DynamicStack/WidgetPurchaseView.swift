//
//  WidgetPurchaseView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public protocol PurchaseProvider {
    var name: String { get }
    var amount: String { get }
    var date: Date { get }
}

public extension PurchaseProvider {
    var time: String {
        time(for: date)
    }

    private func time(for date: Date) -> String {
        Self.relativeDateTimeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static var relativeDateTimeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.formattingContext = .listItem
        formatter.dateTimeStyle = .named
        return formatter
    }
}

extension Order: PurchaseProvider, ImageSourcing {
    public var imageSource: String? {
        "Snabble.Shop.Detail.mapPin"
    }

    public var amount: String {
        formattedPrice(price)
    }

    public var name: String {
        shopName
    }

    // MARK: - Price

    private func formattedPrice(_ price: Int) -> String {
        let divider = pow(10.0, 2 as Int)
        let decimalPrice = Decimal(price) / divider
        return Self.numberFormatter.string(for: decimalPrice)!
    }

    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currency
        return formatter
    }
}

private class OrderViewModel: ObservableObject {
    func load(for projectId: Identifier<Project>?) {
        guard
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId) else {
            return
        }
        OrderList.load(project) { [weak self] result in
            do {
                self?.providers = try result.get().receipts
            } catch {
                self?.providers = [
                    Order(projectId: projectId, id: "2131-sad23", date: Date(), shopId: "1", shopName: "Supermarkt", price: 100, links: Order.OrderLinks(receipt: nil)),
                    Order(projectId: projectId, id: "2131-sad23", date: Date(timeIntervalSinceNow: 500), shopId: "1", shopName: "Supermarkt", price: 100_000, links: Order.OrderLinks(receipt: nil))
                ]
            }
        } // aldi-sued-ch-87cc7e
    }

    @Published var providers: [PurchaseProvider] = [
        Order(projectId: "snabble-sdk-demo-beem8n", id: "2131-sad23", date: Date(), shopId: "1", shopName: "Supermarkt", price: 100, links: Order.OrderLinks(receipt: nil)),
        Order(projectId: "snabble-sdk-demo-beem8n", id: "2131-sad23", date: Date(timeIntervalSinceNow: 500), shopId: "1", shopName: "Supermarkt", price: 100_000, links: Order.OrderLinks(receipt: nil))
    ]
}

public struct WidgetOrderView: View {
    let provider: PurchaseProvider
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let imageSource = provider as? ImageSourcing, let image = imageSource.image {
                    image
                        .resizable()
                        .frame(width: 14, height: 14)
                }
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

public struct WidgetPurchaseView: View {
    let widget: WidgetPurchase
    @ObservedObject var viewModel: DynamicViewModel
    @StateObject private var orderModel = OrderViewModel()
    
    @ViewBuilder
    var orderView: some View {
        if orderModel.providers.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                
                if orderModel.providers.count > 1 {
                    HStack {
                        Text(keyed: "Snabble.Dashboard.lastPurchases")
                        Spacer()
                        Button(action: {
                            print("show all")
                        }) {
                                Text(keyed: "Snabble.Dashboard.lastPurchasesShowAll")
                        }
                    }
                    HStack {
                        WidgetOrderView(provider: orderModel.providers[orderModel.providers.count - 2])
                        WidgetOrderView(provider: orderModel.providers[orderModel.providers.count - 1])
                    }
                } else {
                    Text(keyed: "Snabble.Dashboard.lastPurchase")
                    WidgetOrderView(provider: orderModel.providers[0])
                }
            }
        }
    }
    
    public var body: some View {
        orderView.onAppear {
            orderModel.load(for: widget.projectId)
        }
    }
}
