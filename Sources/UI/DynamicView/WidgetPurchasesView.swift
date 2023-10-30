//
//  WidgetPurchasesView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI
import Combine
import SnabbleCore

public protocol PurchaseProviding {
    var id: String { get }
    var name: String { get }
    var amount: String { get }
    var time: String { get }
    var date: Date { get }
    var unloaded: Bool { get }
    
    var projectId: Identifier<Project> { get }
}

extension Array where Element == PurchaseProviding {
    var title: String {
        return count > 1 ? "Snabble.DynamicView.lastPurchases" : "Snabble.DynamicView.lastPurchase"
    }
}

public class LastPurchasesViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]

    @Published private(set) var projectId: Identifier<Project>? {
        didSet {
            load()
        }
    }
    @Published private(set) var state: LoadingState<[PurchaseProviding]> = .idle
    @Published private(set) var numberOfUnloaded: Int = 0

    private var cancellables = Set<AnyCancellable>()
    struct ImageCache {
        
    }
    private var imageCache: [Identifier<Project>: SwiftUI.Image] = [:]
    
    /// Emits some triigers the action
    /// - `Output` is a `PurchaseProviding`
    public let actionPublisher = PassthroughSubject<PurchaseProviding, Never>()

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
                var unloaded = 0
                
                do {
                    let orderList = try result.get()
                    let providers = orderList.receipts
                    
                    if providers.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(providers)
                        if let new = orderList.numberOfUnloadedReceipts(project) {
                            unloaded = new
                        }
                    }
                } catch {
                    self.state = .empty
                }
                self.numberOfUnloaded = unloaded
            }
        }
    }
}

extension LastPurchasesViewModel {
    func storeImage(projectId: Identifier<Project>, completion: @escaping (UIImage?) -> Void) {
        SnabbleCI.getAsset(.storeIcon, projectId: projectId) { image in
            completion(image)
        }
    }
    public func imageFor(projectId: Identifier<Project>) -> SwiftUI.Image? {
//        guard Snabble.shared.projects.count > 1 else {
//            return nil
//        }
        let image = imageCache[projectId]
        
        if let image {
            return image
        }
        storeImage(projectId: projectId) { image in
            guard let image else {
                return
            }
            self.imageCache[projectId] = Image(uiImage: image)
        }
        return imageCache[projectId]
    }
}

public struct WidgetLastPurchasesView: View {
    let widget: WidgetLastPurchases
    let configuration: DynamicViewConfiguration
    let action: (DynamicAction) -> Void

    @ObservedObject private var viewModel: LastPurchasesViewModel

    init(widget: WidgetLastPurchases, configuration: DynamicViewConfiguration, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.configuration = configuration
        self.action = action

        self.viewModel = LastPurchasesViewModel(projectId: widget.projectId)
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
                        .shadow(radius: configuration.shadowRadius)
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

extension Order: PurchaseProviding {
    public var unloaded: Bool {
        guard let project = project else {
            return false
        }
        return !hasCachedReceipt(project)
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
