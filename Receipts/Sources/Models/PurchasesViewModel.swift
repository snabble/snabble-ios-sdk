//
//  PurchasesViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.09.25.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleTheme

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

@Observable
public class PurchasesViewModel: SnabbleComponents.LoadableObject, @unchecked Sendable {
    public typealias Output = [any PurchaseProviding]

    public let userDefaults: UserDefaults
    private let readStatusManager: ReceiptReadStatusManager

    public var numberOfUnloaded: Int = 0 {
        didSet {
            let newValue = numberOfUnloaded
            Task { @MainActor in
                self.onNumberOfUnloadedChanged?(newValue)
            }
        }
    }

    // New counter for unread
    public var numberOfUnread: Int = 0
    public var listRefreshTrigger: Int = 0

    public var state: SnabbleComponents.LoadingState<[any PurchaseProviding]> = .idle

    private var imageCache: [Identifier<SnabbleCore.Project>: SwiftUI.Image] = [:]

    /// Callback when a receipt action is triggered
    public var onAction: (@MainActor @Sendable (any PurchaseProviding) -> Void)?

    /// Callback when numberOfUnloaded changes
    public var onNumberOfUnloadedChanged: (@MainActor @Sendable (Int) -> Void)?

    public init(
        userDefaults: UserDefaults = .standard,
        readStatusManager: ReceiptReadStatusManager = .shared
    ) {
        self.userDefaults = userDefaults
        self.readStatusManager = readStatusManager
   }

    public func reset() {
        load(reset: true)
    }
    
    public func load() {
        load(reset: false)
    }
    
    public func refresh() {
        load(reset: false, isRefreshing: true)
    }
    
    public func isRead(receiptId: String) -> Bool {
        readStatusManager.isRead(receiptId: receiptId)
    }
    
    /// Mark a receipt as read
    public func markAsRead(receiptId: String) {
        readStatusManager.markAsRead(receiptId: receiptId)
        updateUnreadCount()
        triggerListRefresh()
    }
    
    /// Mark a receipt as unread
    public func markAsUnread(receiptId: String) {
        readStatusManager.markAsUnread(receiptId: receiptId)
        updateUnreadCount()
        triggerListRefresh()
    }

    /// Mark all currently loaded receipts as read
    public func markAllAsRead() {
        guard case .loaded(let purchases) = state else { return }
        let receiptIds = purchases.map { $0.id }
        readStatusManager.markAllAsRead(receiptIds: receiptIds)
        updateUnreadCount()
        triggerListRefresh()
    }
    
    private func triggerListRefresh() {
        listRefreshTrigger += 1
    }

    private func load(reset: Bool, isRefreshing: Bool = false, completion: (@Sendable () -> Void)? = nil) {
        guard let project = Snabble.shared.projects.first else {
            state = .empty
            completion?()
            return
        }
        
        if !isRefreshing {
            state = .loading
        }

        OrderList.load(project) { [weak self] result in
            defer { completion?() }
            
            if let self = self {
                do {
                    let orders = try result.get().receipts
                    
                    if orders.isEmpty {
                        userDefaults.setReceiptCount(0)
                        self.state = .empty
                        self.numberOfUnread = 0
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
                        
                        self.updateUnreadCount()
                    }
                } catch {
                    self.state = .failed(error)
                }
            }
        }
    }
    
    private func updateUnreadCount() {
        guard case .loaded(let purchases) = state else { 
            numberOfUnread = 0
            return 
        }
        
        let readIDs = readStatusManager.allReceiptIds
        let allIDs = Set(purchases.map { $0.id })

        numberOfUnread = allIDs.subtracting(readIDs).count
    }

}

extension PurchasesViewModel {
    public func storeImage(projectId: Identifier<SnabbleCore.Project>, completion: @escaping @Sendable (UIImage?) -> Void) {
        SnabbleCI.getAsset(.storeIcon, projectId: projectId) { image in
            completion(image)
        }
    }
    public func imageFor(projectId: Identifier<SnabbleCore.Project>) -> SwiftUI.Image? {
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

extension PurchasesViewModel {
    public var orders: [Order] {
        if case let .loaded(orders) = state {
            return orders as? [Order] ?? []
        } else {
            return []
        }
    }
}
