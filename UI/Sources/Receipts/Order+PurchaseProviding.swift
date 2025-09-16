//
//  Order+PurchaseProviding.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.09.25.
//

import Foundation

import SnabbleCore

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


extension Order: PurchaseProviding {
    public var loaded: Bool {
        return self.hasReceipt()
    }
    
    // Implementation of the new isRead property
    public var isRead: Bool {
        return ReceiptReadStatusManager.shared.isRead(receiptId: self.id)
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
