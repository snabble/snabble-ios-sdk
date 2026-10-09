//
//  SnabblePay.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-20.
//

import Foundation
import SnabblePayNetwork
import SnabbleNetwork
import Tagged
import SnabbleLogger

/// The methods that you use to receive events from an associated snabblepay object
@MainActor
public protocol SnabblePayDelegate: AnyObject {

    /// Tells the delegate that the snabble pay did update the credentials
    /// - Parameters:
    ///   - snabblePay: The snabblepay object that received the updated credentials
    ///   - credentials: The updated `Credentials`
    func snabblePay(_ snabblePay: SnabblePay, didUpdateCredentials credentials: Credentials?)
}

/// The object that you use integrate SnabblePay
@MainActor
public final class SnabblePay {
    /// The network manager object that handles the network requests
    let networkManager: SnabblePayNetwork.NetworkManager

    /// The environment which is used for all network requests
    public var environment: Environment = .production

    /// The delegate object to receive update events
    public weak var delegate: SnabblePayDelegate?

    /// Identifier for you project
    public var apiKey: String {
        networkManager.apiKey
    }

    /// `URLSession` which is used for all network requests
    public var urlSession: URLSession {
        networkManager.urlSession
    }

    /// The current debug level default value is `.info`
    public static var logLevel: Logger.Level {
        get {
            Logger.shared.logLevel
        }
        set {
            Logger.shared.logLevel = newValue
        }

    }

    /// The object that you use for SnabblePay
    /// - Parameters:
    ///   - apiKey: The key to identify your project
    ///   - credentials: User credentials if available otherwise these will be created and reported to you via `SnabblePayDelegate`
    ///   - urlSession: `URLSession` which should be used for network requests. Default is `.shared`
    public init(apiKey: String, credentials: Credentials?, urlSession: URLSession = .shared) {
        self.networkManager = SnabblePayNetwork.NetworkManager(
            apiKey: apiKey,
            credentials: credentials?.toDTO(),
            urlSession: urlSession
        )
        self.networkManager.delegate = self
    }
}

extension SnabblePay {

    /// Update the `Customer`
    /// - Parameters:
    ///   - id: customer id in your database
    ///   - loyaltyId: loyalty id could be a customer card number
    /// - Returns: The updated customer
    public func updateCustomer(withId id: String?, loyaltyId: String?) async throws -> Customer {
        let endpoint = Endpoints.Customer.put(id: id, loyaltyId: loyaltyId, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Delete customer information
    /// - Returns: The deleted customer
    public func deleteCustomer() async throws -> Customer {
        let endpoint = Endpoints.Customer.delete(onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Checks an `Account.Check`
    /// - Parameters:
    ///   - appUri: Callback URLScheme to inform the app that the process is completed
    ///   - city: The city of residence
    ///   - countryCode: The countryCode [PayOne - ISO 3166](https://docs.payone.com/pages/releaseview.action?pageId=1213959) of residence
    /// - Returns: The account check
    /// - Important: A list of supported two letter country codes from ISO 3166 can be found here: https://docs.payone.com/pages/releaseview.action?pageId=1213959
    public func accountCheck(withAppUri appUri: URL, city: String, countryCode: String) async throws -> Account.Check {
        let endpoint = Endpoints.Accounts.check(
            appUri: appUri,
            city: city,
            countryCode: countryCode,
            onEnvironment: environment
        )
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Returns a list of `Account`
    /// - Returns: A list of accounts
    public func accounts() async throws -> [Account] {
        let endpoint = Endpoints.Accounts.get(onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Returns an `Account` or throws an error if no account can be found with the given `Account.ID`
    /// - Parameter id: The id of the account you are looking for.
    /// - Returns: The account
    public func account(withId id: Account.ID) async throws -> Account {
        let endpoint = Endpoints.Accounts.get(id: id.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Delete the account associated with the given `Account.ID`
    /// - Parameter id: The id of the account you want to delete
    /// - Returns: The deleted account
    public func deleteAccount(withId id: Account.ID) async throws -> Account {
        let endpoint = Endpoints.Accounts.delete(id: id.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Create a new mandate for the given `Account.ID`
    ///
    /// - Parameter accountId: The id of the account your want to use
    /// - Returns: The mandate
    ///
    /// -  The `mandateState` of the given account must be `pending` or `declined`
    public func createMandate(forAccountId accountId: Account.ID) async throws -> Account.Mandate {
        let endpoint = Endpoints.Accounts.Mandate.post(forAccountId: accountId.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Returns the current mandate of the given `Account.ID`
    /// - Parameter accountId: The id of the account to the mandate
    /// - Returns: The mandate
    public func mandate(forAccountId accountId: Account.ID) async throws -> Account.Mandate {
        let endpoint = Endpoints.Accounts.Mandate.get(forAccountId: accountId.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Accepts a mandate
    /// - Parameters:
    ///   - mandateId: The id of the to accepted mandate
    ///   - accountId: The id of the account linked to the mandate
    /// - Returns: The mandate
    ///
    /// - The state of the mandate has to be `pending`
    public func acceptMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID) async throws -> Account.Mandate {
        let endpoint = Endpoints.Accounts.Mandate.accept(
            mandateId: mandateId.rawValue,
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Declines a mandate
    /// - Parameters:
    ///   - mandateId: The id of the to accepted mandate
    ///   - accountId: The id of the account linked to the mandate
    /// - Returns: The mandate
    ///
    /// - The state of the mandate has to be `pending`
    public func declineMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID) async throws -> Account.Mandate {
        let endpoint = Endpoints.Accounts.Mandate.decline(
            mandateId: mandateId.rawValue,
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return try await perform(endpoint) { $0.toModel() }
    }

    /// List of all sessions for the associated user
    /// - Returns: A list of sessions
    public func sessions() async throws -> [Session] {
        let endpoint = Endpoints.Session.get(onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Start a new session
    /// - Parameter accountId: The id of the account you want to use for the session
    /// - Returns: A new `Session`
    public func startSession(withAccountId accountId: Account.ID) async throws -> Session {
        let endpoint = Endpoints.Session.post(withAccountId: accountId.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Refresh a token of a session
    /// - Parameter sessionId: The id of the session which needs to refresh its token
    /// - Returns: A `Session.Token`
    public func refreshToken(withSessionId sessionId: Session.ID) async throws -> Session.Token {
        let endpoint = Endpoints.Session.Token.post(sessionId: sessionId.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Looking for a session with a specific id
    /// - Parameter id: The id of the session you are looking for
    /// - Returns: A `Session`
    public func session(withId id: Session.ID) async throws -> Session {
        let endpoint = Endpoints.Session.get(id: id.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    /// Delete the session associated with the given id
    /// - Parameter id: The id of the session you want to delete
    /// - Returns: The deleted session
    public func deleteSession(withId id: Session.ID) async throws -> Session {
        let endpoint = Endpoints.Session.delete(id: id.rawValue, onEnvironment: environment)
        return try await perform(endpoint) { $0.toModel() }
    }

    private func perform<Response, Model>(_ endpoint: SnabbleNetwork.Endpoint<Response>, toModel transform: (Response) -> Model) async throws -> Model {
        do {
            let response = try await networkManager.publisher(for: endpoint, onEnvironment: environment)
            return transform(response)
        } catch let error as PayHTTPError {
            throw error.toModel()
        } catch {
            throw SnabblePay.Error.unexpected(error)
        }
    }
}
