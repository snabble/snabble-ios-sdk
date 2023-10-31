//
//  LastPurchasesViewModel.swift
//  
//
//  Created by Uwe Tilemann on 31.10.23.
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

private extension UserDefaults {
    var lastReceiptCount: [String: Int] {
        get {
            return object(forKey: "Snabble.DynamicView.lastReceiptCount") as? [String: Int] ?? [:]
        }
        set {
            removeObject(forKey: "Snabble.DynamicView.lastReceiptCount")
            set(newValue, forKey: "Snabble.DynamicView.lastReceiptCount")
        }
    }
    func lastReceiptCount(projectId: Identifier<Project>) -> Int {
        return lastReceiptCount[projectId.rawValue] ?? 0
    }

    func setLastReceiptCount(_ count: Int, for projectId: Identifier<Project>) {
        var newDefaults = lastReceiptCount
        newDefaults[projectId.rawValue] = count

        lastReceiptCount = newDefaults
    }
}

public class LastPurchasesViewModel: ObservableObject, LoadableObject {
    public static let shared = LastPurchasesViewModel(projectId: nil)
    
    typealias Output = [PurchaseProviding]

    @Published private(set) var projectId: Identifier<Project>? {
        didSet {
            load()
        }
    }
    @Published private(set) var state: LoadingState<[PurchaseProviding]> = .idle
    @Published private(set) var numberOfUnloaded: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var imageCache: [Identifier<Project>: SwiftUI.Image] = [:]
    
    /// Emits some triigers the action
    /// - `Output` is a `PurchaseProviding`
    public let actionPublisher = PassthroughSubject<PurchaseProviding, Never>()

    init(projectId: Identifier<Project>?) {
        self.projectId = projectId ?? Snabble.shared.projects.first?.id

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
                let lastReceiptCount = UserDefaults.standard.lastReceiptCount(projectId: projectId)
                
                do {
                    let orderList = try result.get()
                    let providers = orderList.receipts
                    
                    if providers.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(providers)
                        if providers.count > lastReceiptCount {
                            self.numberOfUnloaded = providers.count - lastReceiptCount
                            UserDefaults.standard.setLastReceiptCount(providers.count, for: projectId)
                        }
                    }
                } catch {
                    self.state = .empty
                }
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
        guard Snabble.shared.projects.count > 1 else {
            return nil
        }
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
