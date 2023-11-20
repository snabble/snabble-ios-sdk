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
    
    var projectId: Identifier<Project> { get }
}

private extension UserDefaults {
    var receiptKey: String {
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

    public func load(reset: Bool) {
        guard let project = Snabble.shared.projects.first else {
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

                        if reset {
                            userDefaults.setReceiptCount(providers.count)
                        }
                        
                        if let oldValue = userDefaults.receiptCount() {
                            numberOfUnloaded = providers.count - oldValue
                        } else {
                            userDefaults.setReceiptCount(providers.count)
                        }
                    }
                } catch {
                    self.state = .empty
                }
            }
        }
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
