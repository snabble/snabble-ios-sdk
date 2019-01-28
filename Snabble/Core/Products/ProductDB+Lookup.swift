//
//  ProductDbNetwork.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

extension ProductDB {

    func resolveProductsLookup(_ url: String, _ codes: [(String, String)], _ shopId: String, completion: @escaping (_ result: Result<ScannedProduct, SnabbleError>) -> ()) {
        let group = DispatchGroup()
        var results = [Result<ScannedProduct, SnabbleError>]()

        // lookup each code/template
        for (code, template) in codes {
            group.enter()
            self.resolveProductsLookup(url, code, template, shopId) { result in
                results.append(result)
                group.leave()
            }
        }

        // all requests done - return the first success, if any
        group.notify(queue: DispatchQueue.main) {
            for result in results {
                switch result {
                case .success: return completion(result)
                default: ()
                }
            }

            // no successes found, return the first error
            completion(results[0])
        }
    }

    private func resolveProductsLookup(_ url: String, _ code: String, _ template: String, _ shopId: String, completion: @escaping (_ result: Result<ScannedProduct, SnabbleError>) -> ()) {
        let session = SnabbleAPI.urlSession()

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let parameters = [
            "code": code,
            "template": template,
            "shopID": shopId
        ]
        let query = "code=\(code) template=\(template) shop=\(shopId)"

        self.project.request(.get, url, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        DispatchQueue.main.async {
                            Log.info("online product lookup for \(query): not found")
                            completion(Result.failure(SnabbleError.notFound))
                        }
                        return
                    }

                    do {
                        Log.info("online product lookup for \(query) succeeded")
                        let resolvedProduct = try JSONDecoder().decode(ResolvedProduct.self, from: data)
                        let product = resolvedProduct.convert(code, template)

                        let codeEntry = product.codes.first { $0.code == code }
                        let transmissionCode = codeEntry?.transmissionCode
                        let lookupResult = ScannedProduct(product, transmissionCode, template)
                        completion(Result.success(lookupResult))
                    } catch let error {
                        self.returnError("product parse error: \(error)", completion)
                    }
                } else {
                    self.returnError("error getting product from \(url): \(String(describing: error))", completion)
                }
            }

            task.resume()
        }
    }

    func resolveProductLookup(_ url: String, _ sku: String, _ shopId: String, completion: @escaping (_ result: Result<Product, SnabbleError>) -> ()) {
        let session = SnabbleAPI.urlSession()

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let parameters = [
            "shopID": shopId
        ]
        let query = "sku=\(sku) shop=\(shopId)"

        let requestUrl = url.replacingOccurrences(of: "{sku}", with: sku)

        self.project.request(.get, requestUrl, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        DispatchQueue.main.async {
                            Log.info("online product lookup for \(query): not found")
                            completion(Result.failure(SnabbleError.notFound))
                        }
                        return
                    }

                    do {
                        Log.info("online product lookup for \(query) succeeded")
                        let resolvedProduct = try JSONDecoder().decode(ResolvedProduct.self, from: data)
                        let product = resolvedProduct.convert()
                        completion(Result.success(product))
                    } catch let error {
                        self.returnError("product parse error: \(error)", completion)
                    }
                } else {
                    self.returnError("error getting product from \(url): \(String(describing: error))", completion)
                }
            }

            task.resume()
        }
    }

    private func returnError<T>(_ msg: String, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> () ) {
        self.logError(msg)
        DispatchQueue.main.async {
            completion(Result.failure(SnabbleError(error: ErrorResponse(msg))))
        }
    }

}

extension ScannableCode {
    fileprivate init(_ resolved: ResolvedProduct.ResolvedProductCode) {
        self.code = resolved.code
        self.template = resolved.template
        self.transmissionCode = resolved.transmissionCode
        self.encodingUnit = Unit.from(resolved.encodingUnit)
    }
}

private class ResolvedProduct: Decodable {
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

    enum ResolvedProductType: String, Codable {
        case `default`
        case weighable
        case deposit
    }

    enum ResolvedSaleRestriction: String, Codable {
        case min_age_6
        case min_age_12
        case min_age_14
        case min_age_16
        case min_age_18
        case min_age_21
        case fsk

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
        let transmissionCode, encodingUnit: String?
    }

    struct Price: Codable {
        let listPrice: Int
        let basePrice: String?
        let discountedPrice: Int?
    }

    fileprivate func convert(_ code: String, _ template: String) -> Product {
        let codes = self.codes.map { ScannableCode($0) }
        
        var encodingUnit = Unit.from(self.encodingUnit)
        let code = codes.first { $0.code == code && $0.template == template }
        if let encodingOverride = code?.encodingUnit {
            encodingUnit = encodingOverride
        }

        return convert(codes, encodingUnit)
    }

    fileprivate func convert() -> Product {
        let codes = self.codes.map { ScannableCode($0) }

        return convert(codes, Unit.from(self.encodingUnit))
    }

    private func convert(_ codes: [ScannableCode], _ encodingUnit: Unit?) -> Product {
        let type = ProductType(rawValue: self.weighing) ?? .singleItem

        let product = Product(sku: self.sku,
                              name: self.name,
                              description: self.description,
                              subtitle: self.subtitle,
                              imageUrl: self.imageUrl,
                              basePrice: self.price.basePrice,
                              listPrice: self.price.listPrice,
                              discountedPrice: self.price.discountedPrice,
                              type: type,
                              codes: codes,
                              depositSku: self.deposit?.sku,
                              bundledSku: self.bundledProduct,
                              isDeposit: self.productType == .deposit,
                              deposit: self.deposit?.price.listPrice,
                              saleRestriction: self.saleRestriction?.convert() ?? .none,
                              saleStop: self.saleStop ?? false,
                              bundles: self.bundles?.compactMap { $0.convert() } ?? [],
                              referenceUnit: Unit.from(self.referenceUnit),
                              encodingUnit: encodingUnit)

        return product
    }
}
