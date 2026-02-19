//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 04.11.22.
//

import Foundation
import GRDB

// MARK: - ProductDatabase implementation of ProductProviding

extension ProductDatabase: ProductProviding {
    public var productAvailability: ProductAvailability {
        return defaultAvailability
    }

    /// get a product by its SKU
    ///
    /// - Parameter sku: the SKU of the product to get
    /// - Returns: a `Product` if found; nil otherwise
    public func productBy(sku: String, shopId: Identifier<Shop>) -> Product? {
        guard let db = self.database as? DatabaseQueue else {
            return nil
        }

        return self.productBy(db, sku: sku, shopId: shopId)
    }

    /// get a list of products by their SKUs
    ///
    /// the ordering of the returned products is unspecified
    ///
    /// - Parameter skus: SKUs of the products to get
    /// - Returns: an array of `Product`
    public func productsBy(skus: [String], shopId: Identifier<Shop>) -> [Product] {
        guard let db = self.database as? DatabaseQueue, !skus.isEmpty else {
            return []
        }

        return self.productsBy(db, skus: skus, shopId: shopId)
    }

    /// get a product by one of its scannable codes/template pairs
    public func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct? {
        guard let db = self.database as? DatabaseQueue else {
            return nil
        }

        return self.productBy(db, codes: codes, shopId: shopId)
    }

    /// get products matching `name`
    ///
    /// The project's `useFTS` flag must be `true` for this to work.
    ///
    /// - Parameters:
    ///   - name: the string to search for. The search is case- and diacritic-insensitive
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsBy(name: String, filterDeposits: Bool = true) -> [Product] {
        guard let db = self.database as? DatabaseQueue else {
            return []
        }

        if !self.supportFulltextSearch {
            Log.warn("productsByName called, but supportFulltextSearch == false")
        }

        return self.productsBy(db, name: name, filterDeposits: filterDeposits, shopId: "")
    }

    ///
    /// searches for products whose scannable code starts with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product] {
        guard let db = self.database as? DatabaseQueue else {
            return []
        }

        return self.productsBy(db, prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId)
    }

    // MARK: - asynchronous requests

    private func lookupLocally(forceDownload: Bool) -> Bool {
        return !forceDownload && isUpToDate
    }

    /// asynchronously get a product by its SKU
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - sku: the SKU to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping @Sendable (_ result: Result<Product, ProductLookupError>) -> Void) {
        if self.lookupLocally(forceDownload: forceDownload), let product = self.productBy(sku: sku, shopId: shopId) {
            DispatchQueue.main.async {
                if product.availability == .notAvailable {
                    completion(.failure(.notFound))
                } else {
                    completion(.success(product))
                }
            }
            return
        }

        if let url = self.project.links.resolvedProductBySku?.href {
            self.resolveProductLookup(url: url, sku: sku, shopId: shopId, completion: completion)
        } else {
            completion(.failure(.notFound))
        }
    }

    /// asynchronously get a product by (one of) it scannable codes
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - codes: the codes/templates to look for
    ///   - shopId: the shop id
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping @Sendable (_ result: Result<ScannedProduct, ProductLookupError>) -> Void) {
        if self.lookupLocally(forceDownload: forceDownload), let result = self.scannedProductBy(codes: codes, shopId: shopId) {
            DispatchQueue.main.async {
                if result.product.availability == .notAvailable {
                    completion(.failure(.notFound))
                } else {
                    completion(.success(result))
                }
            }
            return
        }

        if let url = self.project.links.resolvedProductLookUp?.href {
            self.resolveProductsLookup(url, codes, shopId, completion: completion)
        } else {
            completion(.failure(.notFound))
        }
    }

    func logError(_ msg: String) {
        self.project.logError(msg)
    }
}
