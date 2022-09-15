//
//  WidgetPurchasesView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI
import Combine

public protocol PurchaseProviding {
    var id: String { get }
    var name: String { get }
    var amount: String { get }
    var time: String { get }
    var date: Date { get }

    var projectId: Identifier<Project> { get }
}

extension Array where Element == PurchaseProviding {
    var title: String {
        return count > 1 ? "Snabble.DynamicView.lastPurchases" : "Snabble.DynamicView.lastPurchase"
    }
}

class PurchasesViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]

    @Published private(set) var projectId: Identifier<Project>? {
        didSet {
            load()
        }
    }
    @Published private(set) var state: LoadingState<[PurchaseProviding]> = .idle

    private var cancellables = Set<AnyCancellable>()

    init(projectId: Identifier<Project>?) {
        self.projectId = projectId

        if projectId == nil {
            Snabble.shared.checkInManager.shopPublisher
                .sink { [weak self] shop in
                    self?.projectId = shop?.projectId
                }
                .store(in: &cancellables)
        }

    }

    func load() {
        guard let projectId = projectId,
              let project = Snabble.shared.project(for: projectId) else {
            return state = .empty
        }
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
                    self.state = .empty
                }
            }
        }
    }
}

public struct WidgetPurchasesView: View {
    let widget: WidgetLastPurchases
    let action: (DynamicAction) -> Void
    let shadowRadius: CGFloat

    @ObservedObject private var viewModel: PurchasesViewModel

    init(widget: WidgetLastPurchases, shadowRadius: CGFloat, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.action = action
        self.shadowRadius = shadowRadius
        self.viewModel = PurchasesViewModel(projectId: widget.projectId)
    }
    
    public var body: some View {
        AsyncContentView(source: viewModel) { output in
            VStack(alignment: .leading) {
                HStack {
                    Text(keyed: output.title)
                    Spacer()
                    Button(action: {
                        action(.init(widget: widget))
                    }) {
                            Text(keyed: "Snabble.DynamicView.LastPurchases.all")
                    }
                }
                HStack {
                    ForEach(output.prefix(2), id: \.id) { provider in
                        WidgetOrderView(
                            provider: provider
                        ).onTapGesture {
                            action(.init(widget: widget, userInfo: ["id": provider.id]))
                        }
                        .shadow(radius: shadowRadius)
                    }
                }
            }
        }.onAppear {
            viewModel.load()
        }
    }
}

private struct WidgetOrderView: View {
    let provider: PurchaseProviding

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let image = SwiftUI.Image.image(named: "Snabble.DynamicView.LastPurchases.project", domain: provider.projectId) {
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

extension Order: PurchaseProviding {
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
