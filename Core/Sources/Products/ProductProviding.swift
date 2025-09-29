//
//  ProductProviding.swift
//  
//
//  Created by Uwe Tilemann on 04.11.22.
//

import Foundation
import Combine

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

// MARK: - ProductProviding extension supporting Combine publishers to access products

public extension ProductProviding {
    /// get a product publisher by its SKU
    func productPublisherBy(sku: String, shopId: Identifier<Shop>) -> Future<Product?, Never> {
        Future { promise in
            let product = self.productBy(sku: sku, shopId: shopId)
            
            promise(Result.success(product))
        }
    }
    /// get a publisher for a list of products by their SKUs
    func productsPublisherBy(skus: [String], shopId: Identifier<Shop>) -> Future<[Product], Never> {
        Future { promise in
            let products = self.productsBy(skus: skus, shopId: shopId)
            
            promise(Result.success(products))
        }
    }

    /// get a publisher for products matching `name`
    ///
    /// The project's `useFTS` flag must be `true` for this to work.
    ///
    /// - Parameter name: the string to search for. The search is case- and diacritic-insensitive
    /// - Returns: an array of matching `Product`s.
    ///   NB: the returned products do not have price information
    func productsPublisherBy(name: String, filterDeposits: Bool) -> Future<[Product], Never> {
        Future { promise in
            let products = self.productsBy(name: name, filterDeposits: filterDeposits)
            
            promise(Result.success(products))
        }
    }

    /// get a product publisher to search for products whose scannable codes start with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    ///   - templates: if set, the search matches any of the templates passed. if nil, only the built-in `default` template is matched
    /// - Returns: an array of matching `Product`s
    ///   NB: the returned products do not have price information
    func productsPublisherBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> Future<[Product], Never> {
        Future { promise in
            let products = self.productsBy(prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId)
            
            promise(Result.success(products))
        }
    }

    /// get a product by one of its scannable codes/templates
    func scannedProductPublisherBy(codes: [(String, String)], shopId: Identifier<Shop>) -> Future<ScannedProduct?, Never> {
        Future { promise in
            let product = self.scannedProductBy(codes: codes, shopId: shopId)
            
            promise(Result.success(product))
        }
    }
    
    // MARK: - asynchronous variants of the product lookup methods

    /// asynchronously get a product by its SKU
    ///
    /// - Parameters:
    ///   - sku: the sku to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the product found or the error
//    nonisolated func productProviderBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool) -> Future<Product, ProductLookupError> {
//        return Future { promise in
//            self.productBy(sku: sku, shopId: shopId, forceDownload: forceDownload) { result in
//                switch result {
//                case .success(let product):
//                    promise(.success(product))
//                case .failure(let error):
//                    promise(.failure(error))
//                }
//            }
//        }
//    }

    /// asynchronously get a product by (one of) its scannable codes
    ///
    /// - Parameters:
    ///   - codes: the code/template pairs to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the lookup result or the error
//    func scannedProductProviderBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool) -> Future<ScannedProduct, ProductLookupError> {
//        Future { @Sendable promise in
//            self.scannedProductBy(codes: codes, shopId: shopId, forceDownload: forceDownload) { result in
//                switch result {
//                case .success(let product):
//                    promise(.success(product))
//                    
//                case .failure(let error):
//                    promise(.failure(ProductLookupError.from(error) ?? .notFound))
//                }
//
//            }
//        }
//    }
}
