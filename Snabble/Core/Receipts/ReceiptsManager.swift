//
//  ReceiptsManager.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

struct ReceiptData: Codable {
    let total: Int
    let projectId: String
    let shopName: String
    let date: Date
    var pdfPath: URL?

    enum CodingKeys: String, CodingKey {
        case total, projectId, shopName, date
    }

    init(_ total: Int, _ projectId: String, _ shopName: String, _ pdfPath: String) {
        self.total = total
        self.projectId = projectId
        self.shopName = shopName
        self.date = Date()
    }
}

class ReceiptsManager {
    static let shared = ReceiptsManager()

    private init() {}

    func download(_ process: CheckoutProcess, _ project: Project, _ shopName: String) {
        guard
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

            self.saveReceipt(location, process, project, shopName)
        }
        task.resume()
    }

    private func saveReceipt(_ tempFile: URL, _ process: CheckoutProcess, _ project: Project, _ shopName: String) {
        let fileManager = FileManager.default
        let targetPath = self.receiptsPath()
        let uuid = UUID().uuidString
        let targetPDF = targetPath.appendingPathComponent(uuid + ".pdf")
        let targetJSON = targetPath.appendingPathComponent(uuid + ".json")
        let receiptData = ReceiptData(process.checkoutInfo.price.price, project.id, shopName, targetPDF.path)

        do {
            try fileManager.moveItem(at: tempFile, to: targetPDF)
            let data = try JSONEncoder().encode(receiptData)
            try data.write(to: targetJSON, options: .atomic)
        } catch {
            print("save receipt error: \(error)")
            try? fileManager.removeItem(at: targetPDF)
            try? fileManager.removeItem(at: targetJSON)
        }
    }

    func listReceipts() -> [ReceiptData] {
        let fileManager = FileManager.default

        do {
            let receiptsDirectory = self.receiptsPath()
            let files = try fileManager.contentsOfDirectory(atPath: receiptsDirectory.path)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }

            var receipts = [ReceiptData]()
            for json in jsonFiles {
                let jsonPath = receiptsDirectory.appendingPathComponent(json)
                let data = try Data(contentsOf: jsonPath)
                var receipt = try JSONDecoder().decode(ReceiptData.self, from: data)
                receipt.pdfPath = jsonPath.deletingPathExtension().appendingPathExtension("pdf")
                receipts.append(receipt)
            }
            return receipts
        } catch {
            print("list receipts error: \(error)")
            return []
        }
    }

    private func receiptsPath() -> URL {
        let fileManager = FileManager.default
        let docsDir = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let targetPath = docsDir.appendingPathComponent("snabble-receipts", isDirectory: true)
        try? fileManager.createDirectory(at: targetPath, withIntermediateDirectories: true)

        return targetPath
    }
}
