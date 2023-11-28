//
//  PurchasePlaceholder.swift
//  
//
//  Created by Uwe Tilemann on 27.11.23.
//

import SwiftUI
import SnabbleCore

public struct PurchasePlaceholder: Codable {
    public let date: Date
    
    public var id: String
    public var name: String
    public var project: String

    public init(shop: Shop, name: String, transaction: String) {
        self.id = transaction
        self.name = name
        self.date = Date()
        self.project = shop.projectId.rawValue
    }
}

extension PurchasePlaceholder: Equatable {
    public static func == (lhs: PurchasePlaceholder, rhs: PurchasePlaceholder) -> Bool {
        return lhs.id == rhs.id
    }
}

extension UserDefaults {
    var placeholderKey: String {
        "io.snabble.sdk.placeholder"
    }

    public var placeholders: [PurchasePlaceholder] {
        if let data = UserDefaults.standard.object(forKey: placeholderKey) as? Data,
           let placeholders = try? JSONDecoder().decode([PurchasePlaceholder].self, from: data) {
            return placeholders
        }
        return []
    }

    public func removePlaceholder(_ placeholder: PurchasePlaceholder) {
        
        guard !placeholders.isEmpty else {
            return
        }
        guard let index = placeholders.firstIndex(where: { $0 == placeholder }) else {
            return
        }
        var newPlaceholders = placeholders

        newPlaceholders.remove(at: index)
        
        if let encoded = try? JSONEncoder().encode(newPlaceholders) {
            set(encoded, forKey: placeholderKey)
        }
    }

    public func registerPlaceholder(_ placeholder: PurchasePlaceholder) {
        guard placeholders.firstIndex(where: { $0 == placeholder }) == nil else {
            return
        }
        var newPlaceholders = placeholders
        newPlaceholders.append(placeholder)
        
        if let encoded = try? JSONEncoder().encode(newPlaceholders) {
            set(encoded, forKey: placeholderKey)
        }
    }
    static private let invalidationTimeInterval: TimeInterval = 60 // * 60 * 24
    
    func cleanup(placeholders: [PurchasePlaceholder]?, for orders: [Order]) {
        guard let placeholders = placeholders else {
            return
        }
        let invalidate: TimeInterval = Date().timeIntervalSinceNow - Self.invalidationTimeInterval
        
        for placeholder in (placeholders.filter { $0.date.timeIntervalSinceNow < invalidate }) {
            print("found placeholder to remoce: \(placeholder) \(invalidate)")
        }
//        for order in orders {
//            if let index = placeholders.firstIndex(where: { $0.shopId == order.shopId }) {
//                print("found grabAndGo placeholder: \(placeholders[index]) for order: \(order)")
//            }
//        }
    }
    
    public func resetPlaceholders() {
        removeObject(forKey: placeholderKey)
    }
    
    func cleanupPlaceholders(for orders: [Order]) {
        cleanup(placeholders: placeholders, for: orders)
    }
}

extension PurchasePlaceholder: PurchaseProviding {
    public var amount: String {
        ""
    }
    
    public var projectId: Identifier<Project> {
        Identifier<Project>(rawValue: project)
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
