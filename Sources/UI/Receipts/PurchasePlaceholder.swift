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
    public var type: String
    public var name: String
    public var amount: String
    public var project: String

    public init(shop: Shop, name: String) {
        self.id = shop.id.rawValue
        self.type = shop.isGrabAndGo ? "grabAndGo" : "scanAndGo"
        self.name = name
        self.amount = "pending"
        self.date = Date()
        self.project = shop.projectId.rawValue
    }
    public var shopId: String {
        id
    }
    public var projectId: Identifier<Project> {
        Identifier<Project>(rawValue: project)
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

    public var grabAndGoPlaceholders: [PurchasePlaceholder] {
        return placeholders.filter({ $0.type == "grabAndGo" })
    }

    public func removePlaceholder(_ placeholder: PurchasePlaceholder) {
        
        guard !placeholders.isEmpty else {
            return
        }
        guard let index = placeholders.firstIndex(where: { $0.shopId == placeholder.shopId }) else {
            return
        }
        var newPlaceholders = placeholders

        newPlaceholders.remove(at: index)
        
        if let encoded = try? JSONEncoder().encode(newPlaceholders) {
            UserDefaults.standard.set(encoded, forKey: placeholderKey)
        }
    }

    public func registerPlaceholder(_ placeholder: PurchasePlaceholder) {
        var newPlaceholders = placeholders
        newPlaceholders.append(placeholder)
        
        if let encoded = try? JSONEncoder().encode(newPlaceholders) {
            UserDefaults.standard.set(encoded, forKey: placeholderKey)
        }
    }

    func cleanup(placeholders: [PurchasePlaceholder]?, for orders: [Order]) {
        guard let placeholders = placeholders else {
            return
        }

        for order in orders {
            if let index = placeholders.firstIndex(where: { $0.shopId == order.shopId }) {
                print("found grabAndGo placeholder: \(placeholders[index]) for order: \(order)")
            }
        }
    }

    func cleanupGrabAndGo(for orders: [Order]) {
        cleanup(placeholders: grabAndGoPlaceholders, for: orders)
    }
}

extension PurchasePlaceholder: PurchaseProviding {
    
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
