//
//  ProductDbNetwork.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

extension ProductDB {

    func getSingleProduct(_ url: String, _ placeholder: String, _ identifier: String, _ shopId: String, completion: @escaping (Product?, Bool) -> () ) {
        self.getSingleProduct(url, placeholder, identifier, shopId) { (result: LookupResult?, error: Bool) in
            if let result = result {
                completion(result.product, error)
            } else {
                completion(nil, error)
            }
        }
    }

    func getSingleProduct(_ url: String, _ placeholder: String, _ identifier: String, _ shopId: String, completion: @escaping (LookupResult?, Bool) -> () ) {
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let fullUrl = url.replacingOccurrences(of: placeholder, with: identifier)
        let parameters = [ "shopID": shopId ]
        self.project.request(.get, fullUrl, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion(nil, true)
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        DispatchQueue.main.async {
                            Log.info("online product lookup with \(placeholder) \(identifier): not found")
                            completion(nil, false)
                        }
                        return
                    }

                    do {
                        Log.info("online product lookup with \(placeholder) \(identifier) succeeded")
                        let apiProduct = try JSONDecoder().decode(APIProduct.self, from: data)
                        if let depositSku = apiProduct.depositProduct {
                            // get the deposit product
                            self.productBySku(depositSku, shopId) { depositProduct, error in
                                if let deposit = depositProduct?.price {
                                    self.completeProduct(apiProduct, deposit, shopId, completion)
                                } else {
                                    self.returnError("deposit product not found", completion)
                                }
                            }
                        } else {
                            // product w/o deposit
                            self.completeProduct(apiProduct, nil, shopId, completion)
                        }
                    } catch let error {
                        self.returnError("product parse error: \(error)", completion)
                    }
                } else {
                    self.returnError("error getting product from \(fullUrl): \(String(describing: error))", completion)
                }
            }

            task.resume()
        }
    }

    private func returnError(_ msg: String, _ completion: @escaping (LookupResult?, Bool) -> () ) {
        self.logError(msg)
        DispatchQueue.main.sync {
            completion(nil, true)
        }
    }

    private func completeProduct(_ apiProduct: APIProduct, _ deposit: Int?, _ shopId: String, _ completion: @escaping (LookupResult?, Bool) -> () ) {
        let matchingCode = apiProduct.matchingCode

        // is this a bundle or a deposit? then don't do the bundling lookup!
        if apiProduct.bundledProduct != nil || apiProduct.productType == .deposit {
            let result = LookupResult(product: apiProduct.convert(deposit, []), code: matchingCode)
            DispatchQueue.main.async {
                completion(result, false)
            }
            return
        }

        self.getBundlingProducts(self.project.links.bundlesForSku.href, "{bundledSku}", apiProduct.sku, shopId) { bundles, error in
            let result = LookupResult(product: apiProduct.convert(deposit, bundles), code: matchingCode)
            DispatchQueue.main.async {
                completion(result, false)
            }
        }
    }

    private func getBundlingProducts(_ url: String, _ placeholder: String, _ sku: String, _ shopId: String, completion: @escaping (_ bundles: [Product], _ error: Bool) -> ()) {
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let fullUrl = url.replacingOccurrences(of: placeholder, with: sku)
        let parameters = [ "shopID": shopId ]
        self.project.request(.get, fullUrl, parameters: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion([], true)
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        Log.info("online bundle lookup with \(placeholder) \(sku): not found")
                        completion([], false)
                        return
                    }

                    do {
                        let result = try JSONDecoder().decode(APIProducts.self, from: data)
                        Log.info("online bundle lookup for sku \(sku) found \(result.products.count) bundles")
                        self.completeBundles(result.products, shopId, completion)
                    }
                    catch let error {
                        let raw = String(bytes: data, encoding: .utf8)
                        self.logError("bundle parse error: \(error) \(String(describing: raw))")
                        completion([], true)
                    }
                } else {
                    self.logError("error gettings bundles for sku \(sku): \(String(describing: error))")
                    completion([], true)
                }
            }
            task.resume()
        }
    }

    // for a list of bundles, get their respective deposit
    func completeBundles(_ bundles: [APIProduct], _ shopId: String, _ completion: @escaping (_ products: [Product], _ error: Bool) ->() ) {
        let skus = bundles.compactMap { $0.depositProduct }
        if skus.count == 0 {
            completion([], false)
            return
        }

        self.getProductsBySku(self.project.links.productsBySku.href, skus, shopId) { products, error in
            let deposits = Dictionary(uniqueKeysWithValues: products.map { ($0.sku, $0.listPrice) })

            let products = bundles.map { (bundle) -> Product in
                let deposit = deposits[bundle.depositProduct ?? ""]
                return bundle.convert(deposit, [])
            }
            completion(products, false)
        }
    }

    func getProductsBySku(_ url: String, _ skus: [String], _ shopId: String, completion: @escaping (_ products: [Product], _ error: Bool) -> ()) {
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // TODO: is this the right value?
        let timeoutInterval: TimeInterval = 5

        let skuSet = Set(skus)
        var parameters = skuSet.map { URLQueryItem(name: "skus", value: $0) }
        parameters.append(URLQueryItem(name: "shopID", value: shopId))

        self.project.request(.get, url, queryItems: parameters, timeout: timeoutInterval) { request in
            guard let request = request else {
                return completion([], true)
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        Log.info("online products lookup for \(skus): not found")
                        completion([], false)
                        return
                    }

                    do {
                        let result = try JSONDecoder().decode(APIProducts.self, from: data)
                        Log.info("online products lookup for skus \(skus) found \(result.products.count) products")
                        let products = result.products.map { $0.convert(nil, []) }
                        completion(products, false)
                    }
                    catch let error {
                        let raw = String(bytes: data, encoding: .utf8)
                        self.logError("products parse error: \(error) \(String(describing: raw))")
                        completion([], true)
                    }
                } else {
                    self.logError("error getting products for skus \(skus): \(String(describing: error))")
                    completion([], true)
                }
            }
            task.resume()
        }
    }

}

// this is how we get product data from the lookup endpoints
struct APIProducts: Decodable {
    let products: [APIProduct]

    enum CodingKeys: String, CodingKey {
        case products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.products = try container.decodeIfPresent([APIProduct].self, forKey: .products) ?? []
    }
}

struct Code: Codable {
    let code: String
    let transmissionCode: String?
}

struct APIProduct: Codable {
    let sku: String
    let name: String
    let description: String?
    let subtitle: String?
    let depositProduct: String?
    let bundledProduct: String?
    let imageUrl: String?
    let productType: APIProductType
    let transmissionCodes: [String]?
    let price: Int?
    let discountedPrice: Int?
    let basePrice: String?
    let weighing: Weighing?
    let saleRestriction: APISaleRestriction?
    let saleStop: Bool?
    let codes: [Code]
    let matchingCode: String?

    enum APIProductType: String, Codable {
        case `default`
        case weighable
        case deposit
    }

    enum APISaleRestriction: String, Codable {
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

    struct Weighing: Codable {
        let weighedItemIds: [String]
        let weighByCustomer: Bool?
        let referenceUnit: String?
        let encodingUnit: String?
    }

    // convert a JSON representation to our normal model object
    func convert(_ deposit: Int?, _ bundles: [Product]) -> Product {
        var type = ProductType.singleItem
        var weighItemIds: Set<String>?

        if let w = self.weighing {
            if let weighByCustomer = w.weighByCustomer {
                type = weighByCustomer ? .userMustWeigh : .preWeighed
            }
            weighItemIds = Set(w.weighedItemIds)
        }

        let scannableCodes = self.codes.map { $0.code }

        var transmissionCodes = [String: String]()
        for code in self.codes {
            if let xmit = code.transmissionCode {
                transmissionCodes[code.code] = xmit
            }
        }

        return Product(sku: self.sku,
                       name: self.name,
                       description: self.description,
                       subtitle: self.subtitle,
                       imageUrl: self.imageUrl,
                       basePrice: self.basePrice,
                       listPrice: self.price ?? 0,
                       discountedPrice: self.discountedPrice,
                       type: type,
                       scannableCodes: Set(scannableCodes),
                       weighedItemIds: weighItemIds,
                       depositSku: self.depositProduct,
                       bundledSku: self.bundledProduct,
                       isDeposit: self.productType == .deposit,
                       deposit: deposit,
                       saleRestriction: self.saleRestriction?.convert() ?? .none,
                       saleStop: self.saleStop ?? false,
                       bundles: bundles,
                       transmissionCodes: transmissionCodes
        )
    }
}
