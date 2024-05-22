//
//  URLSession+Endpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import Combine

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

extension Publisher where Output == (data: Data, response: URLResponse), Failure == URLError {
    func tryVerifyResponse() -> AnyPublisher<Output, Swift.Error> {
        tryMap { (data, response) throws -> Output in
            try response.verify(with: data)
            return (data, response)
        }
        .eraseToAnyPublisher()
    }
}

extension URLSession {
    func dataTaskPublisher<Response>(
        for endpoint: Endpoint<Response>
    ) -> AnyPublisher<Response, Swift.Error> {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return dataTaskPublisher(for: urlRequest)
            .tryVerifyResponse()
            .map(\.data)
            .tryMap { data in
                try endpoint.parse(data)
            }
            .eraseToAnyPublisher()
    }
}
