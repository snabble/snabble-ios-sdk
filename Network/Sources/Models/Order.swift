//
//  Order.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-04.
//

import Foundation

struct Orders: Decodable {
    let orders: [Order]
}

public struct Order: Decodable {
    public enum PaymentStatus {
        case failed
        case pending
        case successful
    }
    
    public let id: String
    public let date: Date
    
    public let projectId: String
    
    public let shopId: String
    public let shopName: String
    
    public let price: Int
    public let isSuccessful: Bool
    
    let links: Links
    
    struct Links: Codable {
        let receipt: Link?
        
        struct Link: Codable {
            let href: String
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project"
        case id, date, shopName, price
        case shopId = "shopID"
        case links
        case isSuccessful
    }
    
    var receiptPath: String {
        "/\(projectId)/orders/id/\(id)/receipt"
    }
    
    var receiptFileName: String {
        "snabble-order-\(id).pdf"
    }
    
    private static var fileManager: FileManager {
        .default
    }
    
    public var isReceiptAvailable: Bool {
        guard let href = links.receipt?.href, !href.isEmpty else {
            return false
        }
        return true
    }
    
    func saveReceipt(forData data: Data) throws -> URL {
        let documentsDirectory = try Self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentsDirectory.appendingPathComponent(receiptFileName)
        try data.write(to: fileURL)
        return fileURL
    }
    
    public func receiptURL() throws -> URL {
        let documentDirectory = try Self.fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentDirectory.appendingPathComponent(receiptFileName)
    }
    
    public var isReceiptDownloaded: Bool {
        guard let receiptURL = try? receiptURL() else {
            return false
        }
        return Self.fileManager.fileExists(atPath: receiptURL.path)
    }
    
    public func deleteLocalReceipt() throws {
        try Self.fileManager.removeItem(at: receiptURL())
    }
    
    public static func deleteLocalReceipts() throws {
        let cacheDir = try Self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let files = try Self.fileManager.contentsOfDirectory(atPath: cacheDir.path)
        for file in files {
            if file.hasPrefix("snabble-order-") && file.hasSuffix(".pdf") {
                let fullPath = cacheDir.appendingPathComponent(file)
                try Self.fileManager.removeItem(atPath: fullPath.path)
            }
        }
    }
}

extension Order: Swift.Identifiable, Hashable {
    public static func == (lhs: SnabbleNetwork.Order, rhs: SnabbleNetwork.Order) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
