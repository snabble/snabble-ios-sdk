//
//  ReceiptReadStatusManager.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.09.25.
//

import Foundation

import SnabbleCore

/// Manager for persistent storage of the "read" status of receipts
@Observable
public final class ReceiptReadStatusManager {
    public static let shared = ReceiptReadStatusManager()
    
    private let userDefaults: UserDefaults
    private let readStatusKey = "io.snabble.sdk.readReceiptStatus"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Mark a receipt as read
    public func markAsRead(receiptId: String) {
        var readStatus = getReadStatus()
        readStatus.insert(receiptId)
        saveReadStatus(readStatus)
    }
    
    /// Mark a receipt as unread
    public func markAsUnread(receiptId: String) {
        var readStatus = getReadStatus()
        readStatus.remove(receiptId)
        saveReadStatus(readStatus)
    }
    
    /// Checks whether a receipt is marked as read
    public func isRead(receiptId: String) -> Bool {
        return getReadStatus().contains(receiptId)
    }
    
    /// Mark all current receipts as read
    public func markAllAsRead(receiptIds: [String]) {
        var readStatus = getReadStatus()
        receiptIds.forEach { readStatus.insert($0) }
        saveReadStatus(readStatus)
    }
    
    /// Deletes all read statuses (for cleanup/reset)
    public func clearAll() {
        userDefaults.removeObject(forKey: readStatusKey)
    }
    
    // MARK: - Private Methods
    
    private func getReadStatus() -> Set<String> {
        guard let data = userDefaults.data(forKey: readStatusKey),
              let readIds = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return Set<String>()
        }
        return readIds
    }
    
    private func saveReadStatus(_ readStatus: Set<String>) {
        guard let data = try? JSONEncoder().encode(readStatus) else { return }
        userDefaults.set(data, forKey: readStatusKey)
    }
}
