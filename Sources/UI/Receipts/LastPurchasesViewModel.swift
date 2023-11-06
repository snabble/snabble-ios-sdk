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
    struct ReceiptCounter: Codable {
        var last: Int {
            willSet {
                if newValue > last {
                    new = new + newValue - last
                }
            }
        }
        var new: Int
        
        init(last: Int = 0, new: Int = 0) {
            self.last = last
            self.new = new
        }
    }
    static let receiptCountKey = "Snabble.DynamicView.lastReceiptCount"
    
    var lastReceiptCounter: [String: Data] {
        get {
            return dictionary(forKey: Self.receiptCountKey) as? [String: Data] ?? [:]
        }
        set {
            set(newValue, forKey: Self.receiptCountKey)
        }
    }

    func receiptCounter(projectId: Identifier<Project>) -> ReceiptCounter? {
        guard let data = lastReceiptCounter[projectId.rawValue],
              let receiptCounter = try? JSONDecoder().decode(ReceiptCounter.self, from: data) else {
            return nil
        }
        return receiptCounter
    }

    func update(counter: ReceiptCounter, projectId: Identifier<Project>) {
        if let encoded = try? JSONEncoder().encode(counter) {
            lastReceiptCounter[projectId.rawValue] = encoded
        }
    }

    func resetLastUnreadCount(projectId: Identifier<Project>) {
        guard var counter = receiptCounter(projectId: projectId) else {
            return
        }
        counter.new = 0
        update(counter: counter, projectId: projectId)
    }

    func setLastReceiptCount(_ count: Int, for projectId: Identifier<Project>) {
        if var counter = receiptCounter(projectId: projectId) {
            guard count > counter.last else {
                return
            }
            counter.last = count

            update(counter: counter, projectId: projectId)
        } else {
            // create an inital ReceiptCounter and only set a new value if this is the first receipt.
            // Any previous made purchases (where count > 1), made before this update, will not interpreted a new value
            update(counter: ReceiptCounter(last: count, new: count == 1 ? 1 : 0), projectId: projectId)
        }
    }

    func lastReceiptCount(projectId: Identifier<Project>) -> Int {
        return receiptCounter(projectId: projectId)?.last ?? 0
    }

    func lastUnreadCount(projectId: Identifier<Project>) -> Int {
        return receiptCounter(projectId: projectId)?.new ?? 0
    }
}

public class LastPurchasesViewModel: ObservableObject, LoadableObject {
    typealias Output = [PurchaseProviding]

    private(set) var projectId: Identifier<Project>? {
        didSet {
            load()
        }
    }
    private let userDefaults: UserDefaults
    
    @Published private(set) var state: LoadingState<[PurchaseProviding]> = .idle
    @Published public private(set) var numberOfUnloaded: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var imageCache: [Identifier<Project>: SwiftUI.Image] = [:]
    
    /// Emits some triigers the action
    /// - `Output` is a `PurchaseProviding`
    public let actionPublisher = PassthroughSubject<PurchaseProviding, Never>()

    public init(projectId: Identifier<Project>?, userDefaults: UserDefaults = .standard) {
        self.projectId = projectId
        self.userDefaults = userDefaults
        
        if projectId == nil {
            Snabble.shared.checkInManager.shopPublisher
                .sink { [weak self] shop in
                    guard self?.projectId != shop?.projectId else {
                        return
                    }
                    self?.projectId = shop?.projectId
                }
                .store(in: &cancellables)
        }
     }

    public func reset() {
        guard let projectId = projectId else {
            return
        }
        userDefaults.resetLastUnreadCount(projectId: projectId)
        numberOfUnloaded = 0
    }

    public func load() {
        guard let projectId = projectId,
              let project = Snabble.shared.project(for: projectId) else {
            return state = .empty
        }
        
        OrderList.load(project) { [weak self] result in
            if let self = self {
                do {
                    let orderList = try result.get()
                    let providers = orderList.receipts
                    
                    if providers.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(providers)
                        userDefaults.setLastReceiptCount(providers.count, for: projectId)
                        numberOfUnloaded = userDefaults.lastUnreadCount(projectId: projectId)
                    }
                } catch {
                    self.state = .empty
                }
            }
        }
    }
}

extension LastPurchasesViewModel {
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
