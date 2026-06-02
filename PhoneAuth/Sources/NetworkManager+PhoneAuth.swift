//
//  PhoneAuth.swift
//
//
//  Created by Andreas Osberghaus on 2024-02-01.
//

import Foundation
import SnabbleNetwork
import SnabbleUser

public protocol PhoneAuthProviding {
    func startAuthorization(phoneNumber: String) async throws -> String
    func signIn(phoneNumber: String, OTP: String) async throws -> AppUser?
    func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> AppUser?
    func delete(phoneNumber: String) async throws
}

extension NetworkManager: PhoneAuthProviding {

    @discardableResult
    public func startAuthorization(phoneNumber: String) async throws -> String {
        let endpoint = Endpoints.Phone.auth(phoneNumber: phoneNumber)
        _ = try await publisher(for: endpoint)
        return phoneNumber
    }

    @discardableResult
    public func signIn(phoneNumber: String, OTP: String) async throws -> AppUser? {
        let endpoint = Endpoints.Phone.signIn(phoneNumber: phoneNumber, OTP: OTP)
        return try await publisher(for: endpoint)
    }

    @discardableResult
    public func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> AppUser? {
        let endpoint = Endpoints.Phone.changePhoneNumber(phoneNumber: phoneNumber, OTP: OTP)
        return try await publisher(for: endpoint)
    }

    public func delete(phoneNumber: String) async throws {
        let endpoint = Endpoints.Phone.delete()
        _ = try await publisher(for: endpoint)
    }
}
