//
//  OrderList.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public struct OrderList: Decodable, Sendable {
    public let orders: [Order]

    public var receipts: [Order] {
        return orders.filter {
            if let href = $0.links.receipt?.href {
                return !href.isEmpty
            }
            return false
        }
    }
}

public struct Order: Codable, Sendable {
    public let projectId: Identifier<Project>
    public let id: String
    public let date: Date
    public let shopId: String
    public let shopName: String
    public let price: Int
    public let links: OrderLinks

    public struct OrderLinks: Codable, Sendable {
        public let receipt: Link?
    }

    enum CodingKeys: String, CodingKey {
        case projectId = "project", id, date, shopName, price, links
        case shopId = "shopID"
    }
}

extension OrderList {
    public static func load(_ project: Project, completion: @escaping @Sendable (Result<OrderList, SnabbleError>) -> Void ) {
        var url: String?
        if let clientOrdersUrl = Snabble.shared.links.clientOrders?.href {
            url = clientOrdersUrl.replacingOccurrences(of: "{clientID}", with: Snabble.clientId)
        }

        if let appUserId = Snabble.shared.appUser?.id {
            url = Snabble.shared.links.appUserOrders.href.replacingOccurrences(of: "{appUserID}", with: appUserId)
        }

        guard let ordersUrl = url else {
            return completion(Result.failure(SnabbleError.noRequest))
        }

        project.request(.get, ordersUrl, timeout: 0) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request) { (result: Result<OrderList, SnabbleError>) in
                completion(result)
            }
        }
    }

    static func clearCache() {
        let fileManager = FileManager.default
        // swiftlint:disable:next force_try
        let cacheDir = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        do {
            let files = try fileManager.contentsOfDirectory(atPath: cacheDir.path)
            for file in files {
                if file.hasPrefix("snabble-order-") && file.hasSuffix(".pdf") {
                    let fullPath = cacheDir.appendingPathComponent(file)
                    try fileManager.removeItem(atPath: fullPath.path)
                    print("deleted \(file)")
                }
            }
        } catch {
            print(error)
        }
    }
}

extension Order {
    public func receiptURL() -> URL {
        // swiftlint:disable:next force_try
        let cacheDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        return cacheDir.appendingPathComponent("snabble-order-\(self.id).pdf")
    }
    
    public func hasReceipt() -> Bool {
        let targetPath = receiptURL()

        return FileManager.default.fileExists(atPath: targetPath.path)
    }
    
    public func getReceipt(_ project: Project, completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
        // uncomment to force new downloads on every access
        // try? FileManager.default.removeItem(at: cachedReceiptURL(project))

        let targetUrl = receiptURL()
        
        if hasReceipt() {
            completion(.success(targetUrl))
        } else {
            self.download(project, targetUrl) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
   
    public static func download(_ project: Project, receipt: Link?, completion: @escaping @Sendable (Result<URL, Error>) -> Void ) {
        guard let link = receipt?.href else {
            Log.error("error downloading receipt: no receipt link?!?")
            return completion(.failure(SnabbleError.noRequest))
        }
        project.request(.get, link, timeout: 10) { request in
            guard let request = request else {
                completion(.failure(SnabbleError.noRequest))
                return
            }
            
            let session = Snabble.urlSession
            let task = session.downloadTask(with: request) { location, _, error in
                if let error = error {
                    Log.error("error downloading receipt: \(String(describing: error))")
                    return completion(.failure(error))
                }
                
                guard let location = location else {
                    Log.error("error downloading receipt: no location?!?")
                    return completion(.failure(SnabbleError.noRequest))
                }
                completion(.success(location))
            }
            task.resume()
        }
    }
    
    private func download(_ project: Project, _ targetPath: URL, completion: @escaping @Sendable (Result<URL, Error>) -> Void ) {
        
        Order.download(project, receipt: self.links.receipt) { result in
            switch result {
            case .success(let location):
                do {
                    try FileManager.default.moveItem(at: location, to: targetPath)
                    completion(.success(targetPath))
                } catch {
                    Log.error("error saving receipt: \(error)")
                    completion(.failure(SnabbleError.invalid))
                }

            case .failure(let error):
                completion(.failure(error))

            }
        }
    }
}
