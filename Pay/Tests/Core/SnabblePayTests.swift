//
//  SnabblePayTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import Testing
import Foundation
@testable import SnabblePay
import TestHelper

@MainActor
@Suite(.serialized)
final class SnabblePayTests {
    let instance: SnabblePay = SnabblePay(apiKey: "1234", credentials: nil, urlSession: .mockSession)

    nonisolated(unsafe) private var injectedResponse: ((URLRequest) throws -> (HTTPURLResponse, Data))! = { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data())
    }

    init() {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [self] request in
            if request.url?.path == "/apps/register" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, try loadResource(inBundle: .module, filename: "register", withExtension: "json"))
            }

            if request.url?.path == "/apps/token" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, try loadResource(inBundle: .module, filename: "token", withExtension: "json"))
            }

            return try self.injectedResponse(request)
        }
    }

    deinit {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = nil
    }

    nonisolated private func respond(statusCode: Int, resource: String? = nil) throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = try resource.map { try loadResource(inBundle: .module, filename: $0, withExtension: "json") } ?? Data()
            return (response, data)
        }
    }

    @Test func testAccountCheckSuccess() async throws {
        try respond(statusCode: 200, resource: "account-check")
        let accountCheck = try await instance.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE")
        #expect(accountCheck.appUri.absoluteString.isEmpty == false)
    }

    @Test func testAccountCheckFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE")
        }
    }

    @Test func testAccountsSuccess() async throws {
        try respond(statusCode: 200, resource: "accounts-many")
        let accounts = try await instance.accounts()
        #expect(accounts.isEmpty == false)
    }

    @Test func testAccountsFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.accounts()
        }
    }

    @Test func testAccountSuccess() async throws {
        try respond(statusCode: 200, resource: "account-id")
        let account = try await instance.account(withId: "1")
        #expect(account.id.isEmpty == false)
    }

    @Test func testAccountFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.account(withId: "1")
        }
    }

    @Test func testDeleteAccountSuccess() async throws {
        try respond(statusCode: 200, resource: "account-id")
        _ = try await instance.deleteAccount(withId: "1")
    }

    @Test func testDeleteAccountFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.deleteAccount(withId: "1")
        }
    }

    @Test func testMandateSuccess() async throws {
        try respond(statusCode: 200, resource: "mandate-pending")
        let mandate = try await instance.mandate(forAccountId: "1")
        #expect(mandate.id.isEmpty == false)
    }

    @Test func testMandateFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.mandate(forAccountId: "1")
        }
    }

    @Test func testAcceptMandateSuccess() async throws {
        try respond(statusCode: 200, resource: "mandate-pending")
        let mandate = try await instance.acceptMandate(withId: "1", forAccountId: "1")
        #expect(mandate.id.isEmpty == false)
    }

    @Test func testAcceptAccountFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.acceptMandate(withId: "1", forAccountId: "1")
        }
    }

    @Test func testDeclineMandateSuccess() async throws {
        try respond(statusCode: 200, resource: "mandate-accepted")
        let mandate = try await instance.declineMandate(withId: "1", forAccountId: "1")
        #expect(mandate.id.isEmpty == false)
    }

    @Test func testDeclineMandateFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.declineMandate(withId: "2", forAccountId: "1")
        }
    }

    @Test func testSessionsSuccess() async throws {
        try respond(statusCode: 200, resource: "sessions")
        let sessions = try await instance.sessions()
        #expect(sessions.isEmpty == false)
    }

    @Test func testSessionsFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.startSession(withAccountId: "1")
        }
    }

    @Test func testStartSessionSuccess() async throws {
        try respond(statusCode: 200, resource: "sessions-post")
        let session = try await instance.startSession(withAccountId: "1")
        #expect(session.id.isEmpty == false)
    }

    @Test func testStartSessionFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.startSession(withAccountId: "1")
        }
    }

    @Test func testSessionIdSuccess() async throws {
        try respond(statusCode: 200, resource: "sessions-get")
        let session = try await instance.session(withId: "1")
        #expect(session.id.isEmpty == false)
    }

    @Test func testSessionIdFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.session(withId: "1")
        }
    }

    @Test func testSessionDeleteSuccess() async throws {
        try respond(statusCode: 200, resource: "sessions-get")
        let session = try await instance.deleteSession(withId: "1")
        #expect(session.id.isEmpty == false)
    }

    @Test func testSessionDeleteFailure() async throws {
        try respond(statusCode: 500)
        await #expect(throws: SnabblePay.Error.self) {
            _ = try await instance.deleteSession(withId: "1")
        }
    }
}
