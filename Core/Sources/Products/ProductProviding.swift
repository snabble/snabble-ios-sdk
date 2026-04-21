//
//  ProductProviding.swift
//  
//
//  Created by Uwe Tilemann on 04.11.22.
//

import Foundation

// MARK: - ProductProviding protocol to access products

public protocol ProductProviding: AnyObject {
 
    var productAvailability: ProductAvailability { get }

    /// get a product by its SKU
    func productBy(sku: String, shopId: Identifier<Shop>) -> Product?

    /// get a list of products by their SKUs
    func productsBy(skus: [String], shopId: Identifier<Shop>) -> [Product]

    /// get products matching `name`
    ///
    /// The project's `useFTS` flag must be `true` for this to work.
    ///
    /// - Parameter name: the string to search for. The search is case- and diacritic-insensitive
    /// - Returns: an array of matching `Product`s.
    ///   NB: the returned products do not have price information
    func productsBy(name: String, filterDeposits: Bool) -> [Product]

    /// searches for products whose scannable codes start with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    ///   - templates: if set, the search matches any of the templates passed. if nil, only the built-in `default` template is matched
    /// - Returns: an array of matching `Product`s
    ///   NB: the returned products do not have price information
    func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product]

    /// get a product by one of its scannable codes/templates
    func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct?

    // MARK: - asynchronous variants of the product lookup methods

    /// asynchronously get a product by its SKU
    ///
    /// - Parameters:
    ///   - sku: the sku to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the product found or the error
    func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping @Sendable (_ result: Result<Product, ProductLookupError>) -> Void )

    /// asynchronously get a product by (one of) its scannable codes
    ///
    /// - Parameters:
    ///   - codes: the code/template pairs to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the lookup result or the error
    func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping @Sendable (_ result: Result<ScannedProduct, ProductLookupError>) -> Void )
    
}

// MARK: - ProductProviding convenience methods

public extension ProductProviding {
    func productBy(sku: String, shopId: Identifier<Shop>, completion: @escaping @Sendable (_ result: Result<Product, ProductLookupError>) -> Void ) {
        self.productBy(sku: sku, shopId: shopId, forceDownload: false, completion: completion)
    }

    func productsBy(prefix: String, shopId: Identifier<Shop>) -> [Product] {
        return self.productsBy(prefix: prefix, filterDeposits: true, templates: nil, shopId: shopId)
    }

    func productsByName(_ name: String) -> [Product] {
        return self.productsBy(name: name, filterDeposits: true)
    }

    func productBy(codes: [(String, String)], shopId: Identifier<Shop>, completion: @escaping @Sendable (_ result: Result<ScannedProduct, ProductLookupError>) -> Void ) {
        self.scannedProductBy(codes: codes, shopId: shopId, forceDownload: false, completion: completion)
    }
}

// MARK: - async/await variants

public extension ProductProviding {
            promise(Result.success(products))
    func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool = false) async throws -> Product {
        try await withCheckedThrowingContinuation { continuation in
            productBy(sku: sku, shopId: shopId, forceDownload: forceDownload) { result in
                continuation.resume(with: result)
            }
        }
    }

    func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool = false) async throws -> ScannedProduct {
        try await withCheckedThrowingContinuation { continuation in
            scannedProductBy(codes: codes, shopId: shopId, forceDownload: forceDownload) { result in
                continuation.resume(with: result)
            }
        }
    }
}
