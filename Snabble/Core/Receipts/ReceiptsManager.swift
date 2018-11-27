//
//  ReceiptsManager.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

public struct ReceiptData: Codable {
    let id: String

    let projectId: String
    let shopName: String
    let shopId: String
    let date: Date
    let pdfUrl: String
    let total: Int

    var pdfPath: URL?

    enum CodingKeys: String, CodingKey {
        case id, total, projectId, shopName, shopId, pdfUrl, date
    }

    init(_ id: String, _ total: Int, _ projectId: String, _ shop: Shop, _ pdfUrl: String, _ pdfPath: String) {
        self.id = id
        self.total = total
        self.projectId = projectId
        self.shopName = shop.name
        self.shopId = shop.id
        self.pdfUrl = pdfUrl
        self.date = Date()
    }
}

public class ReceiptsManager {
    public static let shared = ReceiptsManager()

    /// set to false to
    public var autoDownload = true

    private init() {}

    func download(_ process: CheckoutProcess, _ project: Project, _ shop: Shop) {
        guard
            self.autoDownload,
            let receiptUrl = process.links.receipt?.href,
            let url = SnabbleAPI.urlFor(receiptUrl),
            let token = SnabbleAPI.tokenRegistry.token(for: project)
        else {
            return
        }

        let session = URLSession(configuration: URLSessionConfiguration.default)
        var request = URLRequest(url: url)
        request.addValue(token, forHTTPHeaderField: "Client-Token")

        let task = session.downloadTask(with: request) { location, response, error in
            guard let location = location else {
                return
            }

            self.saveReceipt(location, process, project, shop, receiptUrl)
        }
        task.resume()
    }

    private func saveReceipt(_ tempFile: URL, _ process: CheckoutProcess, _ project: Project, _ shop: Shop, _ pdfUrl: String) {
        let fileManager = FileManager.default
        let targetPath = self.receiptsPath()
        let uuid = UUID().uuidString
        let targetPDF = targetPath.appendingPathComponent(uuid + ".pdf")
        let targetJSON = targetPath.appendingPathComponent(uuid + ".json")
        let total = process.checkoutInfo.price.price
        let receiptData = ReceiptData(uuid, total, project.id, shop, pdfUrl, targetPDF.path)

        do {
            try fileManager.moveItem(at: tempFile, to: targetPDF)
            let data = try JSONEncoder().encode(receiptData)
            try data.write(to: targetJSON, options: .atomic)
        } catch {
            project.logError("save receipt error: \(error)")
            try? fileManager.removeItem(at: targetPDF)
            try? fileManager.removeItem(at: targetJSON)
        }
    }

    /// get a list of all receipts, sorted by date descending
    public func listReceipts() -> [ReceiptData] {
        let fileManager = FileManager.default

        do {
            let receiptsDirectory = self.receiptsPath()
            let files = try fileManager.contentsOfDirectory(atPath: receiptsDirectory.path)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }

            var receipts = [ReceiptData]()
            for json in jsonFiles {
                let jsonPath = receiptsDirectory.appendingPathComponent(json)
                do {
                    let data = try Data(contentsOf: jsonPath)
                    var receipt = try JSONDecoder().decode(ReceiptData.self, from: data)
                    receipt.pdfPath = jsonPath.deletingPathExtension().appendingPathExtension("pdf")
                    receipts.append(receipt)
                } catch {
                    Log.error("read receipt error: \(error)")
                    try? fileManager.removeItem(at: jsonPath)
                }
            }
            return receipts.sorted { $0.date > $1.date }
        } catch {
            Log.error("list receipts error: \(error)")
            return []
        }
    }

    public func delete(_ receipt: ReceiptData) {
        let fileManager = FileManager.default

        let receiptsDirectory = self.receiptsPath()
        let pdf = receiptsDirectory.appendingPathComponent(receipt.id).appendingPathComponent("pdf")
        let json = receiptsDirectory.appendingPathComponent(receipt.id).appendingPathComponent("json")
        try? fileManager.removeItem(at: pdf)
        try? fileManager.removeItem(at: json)
    }

    private func receiptsPath() -> URL {
        let fileManager = FileManager.default
        let docsDir = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let targetPath = docsDir.appendingPathComponent("snabble-receipts", isDirectory: true)
        try? fileManager.createDirectory(at: targetPath, withIntermediateDirectories: true)

        return targetPath
    }
}
