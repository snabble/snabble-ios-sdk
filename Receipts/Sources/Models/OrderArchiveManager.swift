//
//  OrderArchiveManager.swift
//
//  Copyright © 2026 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

/// Progress snapshot reported during archive creation.
public struct ArchiveProgress: Sendable {
    public let completed: Int
    public let total: Int
    /// Name of the shop whose receipt is currently being downloaded.
    public let currentShopName: String
    /// Date of the order currently being downloaded. `nil` when reporting completion.
    public let currentOrderDate: Date?

    public var fraction: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
}

public enum OrderArchiveError: LocalizedError {
    case noReceiptsAvailable
    case noReceiptsDownloaded

    public var errorDescription: String? {
        switch self {
        case .noReceiptsAvailable:
            return "No receipts available to archive."
        case .noReceiptsDownloaded:
            return "None of the receipts could be downloaded."
        }
    }
}

@MainActor
public struct OrderArchiveManager {

    // MARK: - Public helpers

    /// Root folder of the receipt archive in the app's Documents directory.
    public static var archiveDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Order Archive", isDirectory: true)
    }

    /// `true` when a valid archive index exists on disk.
    public static var hasArchive: Bool {
        FileManager.default.fileExists(atPath: archiveIndexURL.path)
    }

    /// Loads all orders stored in the archive index.
    public static func loadIndex() throws -> [Order] {
        let data = try Data(contentsOf: archiveIndexURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Order].self, from: data)
    }

    /// Returns the expected local PDF URL for an archived order.
    /// The file may not exist if the PDF failed to download during archiving.
    public static func archivedReceiptURL(for order: Order) -> URL {
        archiveDirectoryURL
            .appendingPathComponent(sanitized(order.shopName), isDirectory: true)
            .appendingPathComponent("\(order.id).pdf")
    }

    // MARK: - Archive creation

    /// Downloads all receipts from `orders` into a new folder
    /// named \"Order Archive\" in the Documents directory.
    /// Within that folder each shop gets its own subdirectory and
    /// each file is named by the unique order id.
    /// A hidden `.index.json` containing all archived orders is written to the archive root.
    ///
    /// - Parameters:
    ///   - orders: The orders to archive. Orders without a receipt link are skipped.
    ///   - onProgress: Called after each download attempt with the current progress.
    /// - Returns: URL of the created archive folder.
    public static func createArchive(
        from orders: [Order],
        onProgress: @escaping (ArchiveProgress) -> Void
    ) async throws -> URL {
        let receipts = orders.filter { $0.links.receipt != nil }
        guard !receipts.isEmpty else {
            throw OrderArchiveError.noReceiptsAvailable
        }

        let archiveURL = try makeArchiveDirectory()

        var succeeded = 0
        for (index, order) in receipts.enumerated() {
            onProgress(ArchiveProgress(
                completed: index,
                total: receipts.count,
                currentShopName: order.shopName,
                currentOrderDate: order.date
            ))
            try Task.checkCancellation()

            do {
                if let project = Snabble.shared.project(for: order.projectId) {
                    let pdfURL = try await order.getReceiptAsync(project)
                    let shopURL = try shopDirectory(for: order, in: archiveURL)
                    let targetURL = shopURL.appendingPathComponent("\(order.id).pdf", isDirectory: false)
                    if !FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.copyItem(at: pdfURL, to: targetURL)
                    }
                }
                succeeded += 1
            } catch {
                // Log and continue so a single failure doesn't abort the whole archive
            }
        }

        onProgress(ArchiveProgress(
            completed: receipts.count,
            total: receipts.count,
            currentShopName: "",
            currentOrderDate: nil
        ))

        guard succeeded > 0 else {
            throw OrderArchiveError.noReceiptsDownloaded
        }

        try writeIndex(receipts, to: archiveURL)

        return archiveURL
    }

    // MARK: - Private helpers

    private static var archiveIndexURL: URL {
        archiveDirectoryURL.appendingPathComponent(".index.json")
    }

    private static func writeIndex(_ orders: [Order], to archiveURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(orders)
        try data.write(to: archiveIndexURL, options: .atomic)
    }

    private static func makeArchiveDirectory() throws -> URL {
        try FileManager.default.createDirectory(at: archiveDirectoryURL, withIntermediateDirectories: true)
        return archiveDirectoryURL
    }

    /// Returns (creating if needed) a per-shop subdirectory inside `archiveURL`.
    private static func shopDirectory(for order: Order, in archiveURL: URL) throws -> URL {
        let shopURL = archiveURL.appendingPathComponent(sanitized(order.shopName), isDirectory: true)
        try FileManager.default.createDirectory(at: shopURL, withIntermediateDirectories: true)
        return shopURL
    }

    private static func sanitized(_ name: String) -> String {
        name
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_")).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
}
