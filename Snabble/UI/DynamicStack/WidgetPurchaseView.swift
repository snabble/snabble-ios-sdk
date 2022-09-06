//
//  WidgetPurchaseView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public protocol PurchaseProviding {
    var name: String { get }
    var amount: String { get }
    var date: Date { get }
}

public extension PurchaseProviding {
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

extension Order: PurchaseProviding, ImageSourcing {
    public var imageSource: String? {
        "Snabble.Shop.Detail.mapPin"
    }

    public var amount: String {
        formattedPrice(price)
    }

    public var name: String {
        shopName
    }

    private var project: Project? {
        Snabble.shared.project(for: projectId)
    }

    // MARK: - Price

    private func formattedPrice(_ price: Int) -> String {
        let divider = pow(10.0, project?.decimalDigits ?? 2 as Int)
        let decimalPrice = Decimal(price) / divider
        return numberFormatter.string(for: decimalPrice)!
    }

    private var numberFormatter: NumberFormatter {
        let project = Snabble.shared.project(for: projectId)
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = project?.decimalDigits ?? 2
        formatter.maximumFractionDigits = project?.decimalDigits ?? 2
        formatter.locale = Locale(identifier: project?.locale ?? Locale.current.identifier)
        formatter.currencyCode = project?.currency ?? "EUR"
        formatter.currencySymbol = project?.currencySymbol ?? "€"
        formatter.numberStyle = .currency
        return formatter
    }
}

class OrderViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]

    let projectId: Identifier<Project>

    private var project: Project {
        Snabble.shared.project(for: projectId)!
    }

    @Published private(set) var state: LoadingState<[PurchaseProviding]> = .idle

    init(projectId: Identifier<Project>) {
        self.projectId = projectId
    }

    func load() {
        guard let project = Snabble.shared.project(for: projectId) else {
            return
        }
        state = .loading
        OrderList.load(project) { [weak self] result in
            self?.state = .loaded([
                Order(projectId: "snabble-sdk-demo-beem8n", id: "2131-sad23", date: Date(), shopId: "1", shopName: "Supermarkt", price: 100, links: Order.OrderLinks(receipt: nil)),
                Order(projectId: "snabble-sdk-demo-beem8n", id: "2131-sad23", date: Date(timeIntervalSinceNow: 500), shopId: "1", shopName: "Supermarkt", price: 100_000, links: Order.OrderLinks(receipt: nil))
            ])
//            if let self = self {
//                do {
//                    self.providers = try result.get().receipts
//                } catch {
//                    self.providers = [
//                        Order(projectId: self.projectId, id: "2131-sad23", date: Date(), shopId: "1", shopName: "Supermarkt", price: 100, links: Order.OrderLinks(receipt: nil)),
//                        Order(projectId: self.projectId, id: "2131-sad23", date: Date(timeIntervalSinceNow: 500), shopId: "1", shopName: "Supermarkt", price: 100_000, links: Order.OrderLinks(receipt: nil))
//                    ]
//                }
//            }
        }
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = project.decimalDigits
        formatter.maximumFractionDigits = project.decimalDigits
        formatter.locale = Locale(identifier: project.locale)
        formatter.currencyCode = project.currency
        formatter.currencySymbol = project.currencySymbol
        formatter.numberStyle = .currency
        return formatter
    }

}

public struct WidgetOrderView: View {
    let provider: PurchaseProviding
    
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
    @ObservedObject var viewModel: OrderViewModel
    
    public var body: some View {
        AsyncContentView(source: viewModel) { output in
            VStack(alignment: .leading) {
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
                    ForEach(output.prefix(2), id: \.date) { provider in
                        WidgetOrderView(provider: provider)
                    }
                }
            }
        }
    }
}

enum LoadingState<Value> {
    case idle
    case loading
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

struct AsyncContentView<Source: LoadableObject, Content: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading, .failed:
            EmptyView()
        case .loaded(let output):
            content(output)
        }
    }
}
