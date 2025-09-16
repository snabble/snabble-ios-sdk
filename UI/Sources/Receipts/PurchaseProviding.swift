//
//  PurchaseProviding.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.09.25.
//

import Foundation

import SnabbleCore

public protocol PurchaseProviding {
    var id: String { get }
    var name: String { get }
    var amount: String? { get }
    var time: String { get }
    var date: Date { get }
    var loaded: Bool { get }
    
    // New property for read status
    var isRead: Bool { get }

    var projectId: Identifier<Project> { get }
}

public extension PurchaseProviding {
    var dateString: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(for: date)
    }
}
