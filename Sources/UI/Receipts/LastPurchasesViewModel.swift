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
    var amount: String? { get }
    var time: String { get }
    var date: Date { get }
    var loaded: Bool { get }
    
    var projectId: Identifier<Project> { get }
}

private extension Order {
    var isGrabAndGo: Bool {
        guard let project = Snabble.shared.project(for: projectId) else {
            return false
        }
        let shopID = Identifier<Shop>(rawValue: shopId)

        let filtered = project.shops.filter { (shop: Shop) in
            shop.isGrabAndGo && shop.id == shopID && shop.projectId == projectId
        }
        return !filtered.isEmpty
    }
}

extension UserDefaults {
    private var key: String {
        "io.snabble.sdk.grabandgo.timeIntervals"
    }
    
    func grabAndGoTimeIntervals() -> [TimeInterval] {
        object(forKey: key) as? [TimeInterval] ?? []
    }
    
    public func addGrabAndGoTimeInterval(_ timeInterval: TimeInterval) {
        var intervals = grabAndGoTimeIntervals()
        intervals.append(timeInterval)
        setValue(intervals, forKey: key)
    }
    
    public func removeOldestGrabAndGoInterval() {
        var intervals = grabAndGoTimeIntervals()
        intervals.removeFirst()
        setValue(intervals, forKey: key)
    }
    
    public func clearGrabAndGoIntervals() {
        setValue(nil, forKey: key)
    }
}

private extension UserDefaults {
    private var receiptKey: String {
        "io.snabble.sdk.lastReceiptCount"
    }
    
    func receiptCount() -> Int? {
        guard object(forKey: receiptKey) != nil else {
            return nil
        }
        return integer(forKey: receiptKey)
    }
    
    func setReceiptCount(_ count: Int) {
        setValue(count, forKey: receiptKey)
    }
}

public class LastPurchasesViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]
    
    var projectId: Identifier<Project>? {
        didSet {
            if projectId != oldValue {
                load()
            }
        }
    }
    
    @Published var state: LoadingState<[PurchaseProviding]> = .idle

    public func load() {
        guard let projectId = projectId, let project = Snabble.shared.project(for: projectId) else {
            return state = .empty
        }
        
        state = .idle

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

public class PurchasesViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]
    
    public let userDefaults: UserDefaults
    
    @Published public var numberOfUnloaded: Int = 0
    @Published var state: LoadingState<[PurchaseProviding]> = .idle
    @Published var awaitingReceipts: Bool = false {
        didSet {
            if !awaitingReceipts {
                userDefaults.clearGrabAndGoIntervals()
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var imageCache: [Identifier<Project>: SwiftUI.Image] = [:]
    
    /// Emits some triigers the action
    /// - `Output` is a `PurchaseProviding`
    public let actionPublisher = PassthroughSubject<PurchaseProviding, Never>()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
   }

    public func reset() {
        load(reset: true)
    }
    
    public func load() {
        load(reset: false)
    }

    private func load(reset: Bool) {
        guard let project = Snabble.shared.projects.first else {
            return state = .empty
        }

        state = .idle

        OrderList.load(project) { [weak self] result in
            if let self = self {
                do {
                    let orders = try result.get().receipts
                    
                    if orders.isEmpty {
                        userDefaults.setReceiptCount(0)
                        self.state = .empty
                    } else {
                        self.state = .loaded(orders)
                        
                        if reset {
                            userDefaults.setReceiptCount(orders.count)
                        }
                        
                        if let oldValue = userDefaults.receiptCount() {
                            numberOfUnloaded = orders.count - oldValue
                        } else {
                            userDefaults.setReceiptCount(orders.count)
                            numberOfUnloaded = orders.count
                        }
                        awaitingReceipts(for: orders)
                    }
                } catch {
                    self.state = .empty
                }
            }
        }
    }
    
    func awaitingReceipts(for orders: [Order]) {
        let intervals = userDefaults.grabAndGoTimeIntervals()
        
        guard !intervals.isEmpty else {
            return awaitingReceipts = false
        }
        
        guard intervals.last! + 86_400 >= Date().timeIntervalSince1970 else {
            userDefaults.clearGrabAndGoIntervals()
            awaitingReceipts = false
            return
        }
        
        let latestGrabAndGoTimeintervals = orders
            .filter {
                $0.isGrabAndGo
            }
            .map {
                $0.date.timeIntervalSince1970
            }
            .filter {
                intervals.first! < $0
            }
            .sorted()
        
        
        awaitingReceipts = latestGrabAndGoTimeintervals.count < intervals.count
    }
}

extension PurchasesViewModel {
    public func storeImage(projectId: Identifier<Project>, completion: @escaping (UIImage?) -> Void) {
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
    public var loaded: Bool {
        return self.hasReceipt()
    }

    public var name: String {
        shopName
    }

    private var project: Project? {
        Snabble.shared.project(for: projectId)
    }

    // MARK: - Price

    public var amount: String? {
        formattedPrice(price)
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
