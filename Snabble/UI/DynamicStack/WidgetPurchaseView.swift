//
//  WidgetPurchaseView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

protocol PurchaseProvider: Swift.Identifiable {
    var imageSource: String? { get }
    var name: String { get }
    var amount: String { get }
    var date: Date { get }
}

private class OrderViewModel: ObservableObject {
    
    struct Order: PurchaseProvider, ImageSourcing {
        let id = UUID()
        let imageSource: String?
        let name: String
        let amount: String
        let date: Date
        
        var time: String {
            return Self.time(for: date)
        }
        
        fileprivate static func time(for date: Date) -> String {
            return Self.relativeDateTimeFormatter.localizedString(for: date, relativeTo: Date())
        }

        private static var relativeDateTimeFormatter: RelativeDateTimeFormatter = {
            let formatter = RelativeDateTimeFormatter()
            formatter.formattingContext = .listItem
            formatter.dateTimeStyle = .named
            return formatter
        }()

        private static var dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter
        }()

        private static var timeFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .medium
            return dateFormatter
        }()

        private static func relativeDateString(for past: Date) -> String {
            let now = Date()
            let diff = Int(now.timeIntervalSinceReferenceDate - past.timeIntervalSinceReferenceDate)

            var date = DateComponents()
            switch diff {
            case 0..<45:
                date.second = diff
            case 45..<90:
                return Asset.localizedString(forKey: "Home.PreviousPurchases.oneMinuteAgo")
            case 90..<3000:
                date.minute = (diff + 30) / 60
            case 3000..<6000:
                return Asset.localizedString(forKey: "Home.PreviousPurchases.oneHourAgo")
            case 6000..<86400:
                date.hour = (diff + 2400) / 3600
            default:
                return "\(Self.dateFormatter.string(from: past))\n\(Self.timeFormatter.string(from: past)) \(Asset.localizedString(forKey: "Snabble.Receipts.oClock"))"
            }

            let fmt = DateComponentsFormatter()
            fmt.unitsStyle = .full

            let str = fmt.string(from: date) ?? ""
            return Asset.localizedString(forKey: "Home.PreviousPurchases.ago", arguments: str)
        }

    }
    @Published var orders: [Order] = {
        return [
            Order(imageSource: "Snabble.Shop.Detail.mapPin", name: "SDK Supermarket", amount: "€ 3,20", date: Date()),
            Order(imageSource: "Snabble.Shop.Detail.mapPin", name: "SDK Supermarket", amount: "€ 16,99", date: Date(timeIntervalSinceNow: -3600)),
            Order(imageSource: "Snabble.Shop.Detail.mapPin", name: "SDK Supermarket", amount: "€ 201.640,00", date: Date())
        ]
    }()
}

public struct WidgetOrderView: View {
    fileprivate let order: OrderViewModel.Order
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let image = order.image {
                    image
                        .resizable()
                        .frame(width: 14, height: 14)
                }
                Spacer()
                Text(order.amount)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
            Text(order.name)
                .font(.subheadline)
            
            Text(order.time)
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
        if orderModel.orders.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                
                if orderModel.orders.count > 1 {
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
                        WidgetOrderView(order: orderModel.orders[orderModel.orders.count - 2])
                        WidgetOrderView(order: orderModel.orders[orderModel.orders.count - 1])
                    }
                } else {
                    Text(keyed: "Snabble.Dashboard.lastPurchase")
                    WidgetOrderView(order: orderModel.orders[0])
                }
            }
        }
    }
    
    public var body: some View {
        orderView
    }
}
