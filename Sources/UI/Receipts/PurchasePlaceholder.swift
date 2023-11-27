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
    
    public enum ShopType: String, Codable {
        case grabAndGo
        case scanAndGo
    }
    public var id: String
    public var type: ShopType
    public var name: String
    public var amount: String
    public var projectId: SnabbleCore.Identifier<SnabbleCore.Project>

    public init(shop: Shop, name: String) {
        self.id = shop.id.rawValue
        self.type = shop.isGrabAndGo ? .grabAndGo : .scanAndGo
        self.name = name
        self.amount = "pending"
        self.date = Date()
        self.projectId = shop.projectId
    }
}

extension UserDefaults {
    var placeholderKey: String {
        "io.snabble.sdk.placeholder"
    }

    var placeholders: [PurchasePlaceholder]? {
        guard let array = object(forKey: placeholderKey) as? [PurchasePlaceholder] else {
            return nil
        }
        return array
    }
    var grabAndGoPlaceholders: [PurchasePlaceholder]? {
        return placeholders?.filter( { $0.type == .grabAndGo })
    }
    func placeholderCount() -> Int? {
        return placeholders?.count
    }

    func removePlaceholder(_ placeholder: PurchasePlaceholder) {
        guard var placeholders = placeholders else {
            return
        }
        guard let index = placeholders.firstIndex(where: { $0.id == placeholder.id }) else {
            return
        }
        placeholders.remove(at: index)
        setValue(placeholders, forKey: placeholderKey)
    }

    func registerPlaceholder(_ placeholder: PurchasePlaceholder) {
        var placeholders = placeholders ?? []
        placeholders.append(placeholder)
        setValue(placeholders, forKey: placeholderKey)
    }

    func cleanup(placeholders: [PurchasePlaceholder]?, for orders: [Order]) {
        guard var placeholders = placeholders else {
            return
        }

        for order in orders {
            if let index = placeholders.firstIndex(where: { $0.id == order.shopId }) {
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
