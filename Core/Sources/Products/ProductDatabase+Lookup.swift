//
//  ProductDatabase+Lookup.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

extension ProductDatabase {
    func resolveProductsLookup(_ url: String, _ codes: [(String, String)], _ shopId: Identifier<Shop>, completion: @escaping (_ result: Result<ScannedProduct, ProductLookupError>) -> Void) {
        let group = DispatchGroup()
        var results = [Result<ScannedProduct, ProductLookupError>]()
        let mutex = Mutex()

        // lookup each code/template
        for (code, template) in codes {
            group.enter()
            self.resolveProductsLookup(url, code, template, shopId) { result in
                mutex.lock()
                results.append(result)
                mutex.unlock()
                group.leave()
            }
        }

        // all requests done - return the first success, if any
        group.notify(queue: DispatchQueue.main) {
            var result = results[0]
            var found = 0
            for res in results {
                switch res {
                case .success:
                    result = res
                    found += 1
                default: ()
                }
            }

            // more than one success? log this
            if found > 1 {
                let msg = "got \(found) matches for lookup \(codes)"
                Log.warn(msg)
                let event = AppEvent(log: msg, project: self.project)
                event.post()
            }
            completion(result)
        }
    }

    private func resolveProductsLookup(_ url: String, _ code: String, _ template: String, _ shopId: Identifier<Shop>,
                                       completion: @escaping (_ result: Result<ScannedProduct, ProductLookupError>) -> Void) {
        let session = Snabble.urlSession

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let parameters = [
            "code": code,
            "template": template,
            "shopID": shopId.rawValue
        ]
        let query = "code=\(code) template=\(template) shop=\(shopId.rawValue)"

        self.project.request(.get, url, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion(Result.failure(.notFound))
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let lookupError = ProductLookupError.from(error) {
                    let msg = "error getting product from \(url) \(query): \(String(describing: error))"
                    self.returnError(msg, lookupError, completion)
                    return
                }

                if let lookupError = ProductLookupError.from(response) {
                    let msg = "error getting product from \(url) \(query): \(lookupError)"
                    self.returnError(msg, lookupError, completion)
                    return
                }

                if let data = data {
                    do {
                        Log.info("online product lookup for \(query) succeeded")
                        let resolvedProduct = try JSONDecoder().decode(ResolvedProduct.self, from: data)
                        let product = resolvedProduct.convert(code, template)

                        let codeEntry = product.codes.first { $0.code == code }
                        let lookupResult = ScannedProduct(product, code, codeEntry?.transmissionCode,
                                                          templateId: template,
                                                          transmissionTemplateId: codeEntry?.transmissionTemplate,
                                                          specifiedQuantity: codeEntry?.specifiedQuantity)
                        if lookupResult.product.availability == .notAvailable {
                            completion(.failure(.notFound))
                        } else {
                            completion(.success(lookupResult))
                        }
                    } catch let error {
                        let msg = "product parse error: \(error)"
                        self.returnError(msg, .notFound, completion)
                    }
                    return
                }

                let msg = "error getting product from \(url): \(String(describing: error))"
                self.returnError(msg, .notFound, completion)
            }

            task.resume()
        }
    }

    func resolveProductLookup(url: String, sku: String, shopId: Identifier<Shop>, completion: @escaping (_ result: Result<Product, ProductLookupError>) -> Void) {
        let session = Snabble.urlSession

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let parameters = [
            "shopID": shopId.rawValue
        ]
        let query = "sku=\(sku) shop=\(shopId.rawValue)"

        let requestUrl = url.replacingOccurrences(of: "{sku}", with: sku)

        self.project.request(.get, requestUrl, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion(.failure(.notFound))
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let lookupError = ProductLookupError.from(error) {
                    let msg = "error getting product from \(url) \(query): \(String(describing: error))"
                    self.returnError(msg, lookupError, completion)
                    return
                }

                if let lookupError = ProductLookupError.from(response) {
                    let msg = "error getting product from \(url) \(query): \(lookupError)"
                    self.returnError(msg, lookupError, completion)
                    return
                }

                if let data = data {
                    do {
                        Log.info("online product lookup for \(query) succeeded")
                        let resolvedProduct = try JSONDecoder().decode(ResolvedProduct.self, from: data)
                        let product = resolvedProduct.convert()
                        if product.availability == .notAvailable {
                            completion(.failure(.notFound))
                        } else {
                            completion(.success(product))
                        }
                    } catch let error {
                        let msg = "product parse error: \(error)"
                        self.returnError(msg, .notFound, completion)
                    }
                    return
                }

                let msg = "error getting product from \(url): \(String(describing: error))"
                self.returnError(msg, .notFound, completion)
            }

            task.resume()
        }
    }

    private func returnError<T>(_ msg: String, _ error: ProductLookupError, _ completion: @escaping (_ result: Result<T, ProductLookupError>) -> Void ) {
        if error != .notFound {
            self.logError(msg)
        }
        DispatchQueue.main.async {
            completion(.failure(error))
        }
    }

}

private final class ResolvedProduct: Decodable {
    let sku, name: String
    let description, subtitle: String?
    let imageUrl: String?
    let productType: ResolvedProductType
    let saleStop: Bool?
    let codes: [ResolvedProductCode]
    let price: Price
    let saleRestriction: ResolvedSaleRestriction?
    let deposit: ResolvedProduct?
    let bundles: [ResolvedProduct]?
    let bundledProduct: String?
    let weighing: Int
    let weighByCustomer: Bool?
    let referenceUnit: String?
    let encodingUnit: String?
    let scanMessage: String?
    let availability: ResolvedProductAvailability?
    let notForSale: Bool?

    enum ResolvedProductType: String, Codable {
        case `default`
        case weighable
        case deposit
    }

    enum ResolvedProductAvailability: String, Codable {
        case inStock
        case listed
        case notAvailable

        func convert() -> ProductAvailability {
            switch self {
            case .inStock: return .inStock
            case .listed: return .listed
            case .notAvailable: return .notAvailable
            }
        }
    }

    enum ResolvedSaleRestriction: String, Codable {
        // swiftlint:disable identifier_name
        case min_age_6
        case min_age_12
        case min_age_14
        case min_age_16
        case min_age_18
        case min_age_21
        case fsk
        // swiftlint:enable identifier_name

        func convert() -> SaleRestriction {
            switch self {
            case .min_age_6: return .age(6)
            case .min_age_12: return .age(12)
            case .min_age_14: return .age(14)
            case .min_age_16: return .age(16)
            case .min_age_18: return .age(18)
            case .min_age_21: return .age(21)
            case .fsk: return .fsk
            }
        }
    }

    struct ResolvedProductCode: Codable {
        let code, template: String
        let transmissionCode: String?
        let encodingUnit: String?
        let isPrimary: Bool?
        let specifiedQuantity: Int?
        let transmissionTemplate: String?
    }

    struct Price: Codable {
        let listPrice: Int?
        let basePrice: String?
        let discountedPrice: Int?
        let customerCardPrice: Int?
    }

    fileprivate func convert(resolvedCodes: [ResolvedProduct.ResolvedProductCode]) -> [ScannableCode] {
        var primaryTransmission: String?
        if let primaryIndex = resolvedCodes.firstIndex(where: { $0.isPrimary == true }) {
            let transmit = resolvedCodes[primaryIndex].transmissionCode
            let code = resolvedCodes[primaryIndex].code
            primaryTransmission = transmit ?? code
        }

        return resolvedCodes.map {
            ScannableCode(code: $0.code,
                          template: $0.template,
                          transmissionCode: primaryTransmission ?? $0.transmissionCode,
                          encodingUnit: Units.from($0.encodingUnit),
                          specifiedQuantity: $0.specifiedQuantity,
                          transmissionTemplate: $0.transmissionTemplate)
        }
    }

    fileprivate func convert(_ code: String, _ template: String) -> Product {
        let codes = self.convert(resolvedCodes: self.codes)

        var encodingUnit = Units.from(self.encodingUnit)
        let code = codes.first { $0.code == code && $0.template == template }
        if let encodingOverride = code?.encodingUnit {
            encodingUnit = encodingOverride
        }

        return self.convert(codes, encodingUnit)
    }

    fileprivate func convert() -> Product {
        let codes = self.convert(resolvedCodes: self.codes)

        return self.convert(codes, Units.from(self.encodingUnit))
    }

    private func convert(_ codes: [ScannableCode], _ encodingUnit: Units?) -> Product {
        let type = ProductType(rawValue: self.weighing)

        let bundles = self.bundles?
            .compactMap { $0.convert() }
            .filter { $0.availability != .notAvailable }

        let product = Product(sku: self.sku,
                              name: self.name,
                              description: self.description,
                              subtitle: self.subtitle,
                              imageUrl: self.imageUrl,
                              basePrice: self.price.basePrice,
                              listPrice: self.price.listPrice ?? 0,
                              discountedPrice: self.price.discountedPrice,
                              customerCardPrice: self.price.customerCardPrice,
                              type: type,
                              codes: codes,
                              depositSku: self.deposit?.sku,
                              bundledSku: self.bundledProduct,
                              isDeposit: self.productType == .deposit,
                              deposit: self.deposit?.price.listPrice,
                              saleRestriction: self.saleRestriction?.convert() ?? .none,
                              saleStop: self.saleStop ?? false,
                              bundles: bundles ?? [],
                              referenceUnit: Units.from(self.referenceUnit),
                              encodingUnit: encodingUnit,
                              scanMessage: self.scanMessage,
                              availability: self.availability?.convert() ?? .inStock,
                              notForSale: self.notForSale ?? false)

        return product
    }
}
