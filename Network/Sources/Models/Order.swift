//
//  Order.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-04.
//

import Foundation

struct Orders: Codable {
    let orders: [Order]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orders = try container.decode([Order].self, forKey: .orders).filter {
            guard let href = $0.links.receipt?.href, !href.isEmpty else {
                return false
            }
            return true
        }
    }
}

public struct Order: Codable {
    public let id: String
    public let date: Date
    
    public let projectId: String
    
    public let shopId: String
    public let shopName: String
    
    public let price: Int
    
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
