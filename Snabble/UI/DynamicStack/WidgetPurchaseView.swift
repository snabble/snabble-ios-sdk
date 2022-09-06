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
    var time: String { get }
    var date: Date { get }
}

extension Order: PurchaseProviding, ImageSourcing {
    public var imageSource: String? {
        "Snabble.Shop.Detail.mapPin"
    }

    public var name: String {
        shopName
    }

    private var project: Project? {
        Snabble.shared.project(for: projectId)
    }

    // MARK: - Price

    public var amount: String {
        formattedPrice(price) ?? "N/A"
    }

    private func formattedPrice(_ price: Int) -> String? {
        let divider = pow(10.0, project?.decimalDigits ?? 2 as Int)
        let decimalPrice = Decimal(price) / divider
        return numberFormatter(for: project).string(for: decimalPrice)
    }

    private func numberFormatter(for project: Project?) -> NumberFormatter {
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

    // MARK: - Date
    public var time: String {
        time(for: date)
    }

    private func time(for date: Date) -> String {
        Self.relativeDateTimeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static var relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.formattingContext = .listItem
        formatter.dateTimeStyle = .named
        return formatter
    }()
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
            if let self = self {
                do {
                    let providers = try result.get().receipts
                    if providers.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(providers)
                    }
                } catch {
                    self.state = .failed(error)
                }
            }
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
    case empty
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
        case .loading, .failed, .empty:
            EmptyView()
        case .loaded(let output):
            content(output)
        }
    }
}
