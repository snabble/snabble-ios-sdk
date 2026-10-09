//
//  URLSession+Endpoint.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleLogger
import SnabbleNetwork

private extension URLResponse {
    func verify(with data: Data) throws {
        guard let httpResponse = self as? HTTPURLResponse else {
            Logger.shared.error("Unknown Response \(self)")
            throw PayHTTPError.invalidResponse(self)
        }
        guard httpResponse.httpStatusCode.responseType == .success else {
            let error: Endpoints.Error = (try? Endpoints.jsonDecoder.decode(Endpoints.Error.self, from: data)) ?? .unknown
            Logger.shared.error("Invalid Response with errorObject \(error)")
            throw PayHTTPError.validationError(httpResponse.httpStatusCode, error)
        }
    }
}

extension URLSession {
    func data<Response>(for endpoint: Endpoint<Response>) async throws -> Response {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest()
        } catch {
            Logger.shared.error("Invalid request \(error)")
            throw PayHTTPError.invalidRequestError("\(error)")
        }
        Logger.shared.debug("Start URLRequest: \(urlRequest)")
        do {
            let (data, response) = try await self.data(for: urlRequest)
            try response.verify(with: data)
            return try endpoint.parse(data)
        } catch let error as PayHTTPError {
            throw error
        } catch let error as URLError {
            throw PayHTTPError.transportError(error)
        } catch let error as DecodingError {
            Logger.shared.error("Decoding error \(error)")
            throw PayHTTPError.decodingError(error)
        } catch {
            throw PayHTTPError.unexpected(error)
        }
    }
}
