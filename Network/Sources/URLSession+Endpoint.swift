//
//  URLSession+Endpoint.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

private extension URLResponse {
    func verify(with data: Data) throws {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw HTTPError.unknown(self)
        }
        guard httpResponse.httpStatusCode.responseType == .success else {
            var clientError: ClientError?
            if httpResponse.httpStatusCode.responseType == .clientError {
                clientError = try? Endpoints.jsonDecoder.decode(ClientError.self, from: data)
            }
            throw HTTPError.invalid(httpResponse, clientError)
        }
    }
}

extension URLSession {
    func data<Response>(for endpoint: Endpoint<Response>) async throws -> Response {
        let urlRequest = try endpoint.urlRequest()
        let (data, response) = try await self.data(for: urlRequest)
        try response.verify(with: data)
        return try endpoint.parse(data)
    }

    func downloadFile(from url: URL) async throws -> URL {
        let (location, _) = try await download(from: url)
        return location
    }
}
