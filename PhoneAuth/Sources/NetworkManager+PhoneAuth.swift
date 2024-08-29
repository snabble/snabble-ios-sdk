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

//public protocol PhoneAuthDelegate: AnyObject {
//    func phoneAuth(_ phoneAuth: PhoneAuth, didReceiveAppUser: SnabbleUser.AppUser)
//}
//
//public protocol PhoneAuthDataSource: AnyObject {
//    func appUserId(forConfiguration configuration: Configuration) -> SnabbleUser.AppUser?
//    func projectId(forConfiguration configuration: Configuration) -> String?
//}

//public class PhoneAuth {
//    public weak var delegate: PhoneAuthDelegate?
//    public weak var dataSource: PhoneAuthDataSource?
//
//    public let networkManager: NetworkManager
//
//    public var configuration: Configuration {
//        networkManager.configuration.fromDTO()
//    }
//    
//    public init(networkManager: NetworkManager, urlSession: URLSession = .shared) {
//        self.networkManager = networkManager
//    }
//    
//    public init(configuration: Configuration, urlSession: URLSession = .shared) {
//        self.networkManager = NetworkManager(
//            configuration: configuration.toDTO(),
//            urlSession: urlSession
//        )
//        self.networkManager.delegate = self
//    }
//}

extension NetworkManager: PhoneAuthProviding {

    private func useContinuation<Value, Response>(endpoint: Endpoint<Response>, receiveValue: @escaping (Response, CheckedContinuation<Value, any Error>) -> Void) async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher(for: endpoint)
                .mapHTTPErrorIfPossible()
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

extension Publisher {
    public func mapHTTPErrorIfPossible() -> AnyPublisher<Self.Output, Error> {
        mapError {
            guard let error = $0 as? SnabbleNetwork.HTTPError else {
                return $0
            }
            return error.fromDTO()
        }
        .eraseToAnyPublisher()
    }
}

//extension PhoneAuth: NetworkManagerDelegate {
//    public func networkManager(_ networkManager: SnabbleNetwork.NetworkManager, appUserForConfiguration configuration: SnabbleNetwork.Configuration) -> SnabbleUser.AppUser? {
//        dataSource?.appUserId(forConfiguration: configuration.fromDTO())
//    }
//
//    public func networkManager(_ networkManager: SnabbleNetwork.NetworkManager, appUserUpdated appUser: SnabbleUser.AppUser) {
//        delegate?.phoneAuth(self, didReceiveAppUser: appUser)
//    }
//
//    public func networkManager(_ networkManager: SnabbleNetwork.NetworkManager, projectIdForConfiguration configuration: SnabbleNetwork.Configuration) -> String? {
//        dataSource?.projectId(forConfiguration: configuration.fromDTO())
//    }
//}
