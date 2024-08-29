//
//  PhoneAuth.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-01.
//

import Foundation
import SnabbleNetwork
import Combine
import SnabbleUser

public protocol PhoneAuthProviding {
    func startAuthorization(phoneNumber: String) async throws -> String
    func signIn(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser?
    func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser?
    func delete(phoneNumber: String) async throws
}

extension NetworkManager: PhoneAuthProviding {

    private func useContinuation<Value, Response>(endpoint: Endpoint<Response>, receiveValue: @escaping (Response, CheckedContinuation<Value, any Error>) -> Void) async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher(for: endpoint)
                .receive(on: RunLoop.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()

                } receiveValue: { response in
                    receiveValue(response, continuation)
                }
        }
    }
    
    @discardableResult
    public func startAuthorization(phoneNumber: String) async throws -> String {
        let endpoint = Endpoints.Phone.auth(
            phoneNumber: phoneNumber
        )

        return try await useContinuation(endpoint: endpoint) { _, continuation in
            continuation.resume(with: .success(phoneNumber))
        }
    }

    @discardableResult
    public func signIn(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser? {
        let endpoint = Endpoints.Phone.signIn(
            phoneNumber: phoneNumber,
            OTP: OTP
        )

        return try await useContinuation(endpoint: endpoint) { response, continuation in
            continuation.resume(with: .success(response))
        }
    }

    @discardableResult
    public func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> SnabbleUser.AppUser? {
        let endpoint = Endpoints.Phone.changePhoneNumber(
            phoneNumber: phoneNumber,
            OTP: OTP
        )

        return try await useContinuation(endpoint: endpoint) { response, continuation in
            continuation.resume(with: .success(response))
        }
    }

    public func delete(phoneNumber: String) async throws {
        let endpoint = Endpoints.Phone.delete()

        return try await useContinuation(endpoint: endpoint) { response, continuation in
            continuation.resume(with: .success(response))
        }
    }
}
