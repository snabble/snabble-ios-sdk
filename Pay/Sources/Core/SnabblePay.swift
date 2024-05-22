//
//  SnabblePay.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-20.
//

import Foundation
import SnabblePayNetwork
import Combine
import Tagged
import SnabbleLogger

/// The methods that you use to receive events from an associated snabblepay object
public protocol SnabblePayDelegate: AnyObject {

    /// Tells the delegate that the snabble pay did update the credentials
    /// - Parameters:
    ///   - snabblePay: The snabblepay object that received the updated credentials
    ///   - credentials: The updated `Credentials`
    func snabblePay(_ snabblePay: SnabblePay, didUpdateCredentials credentials: Credentials?)
}

/// The object that you use integrate SnabblePay
public class SnabblePay {
    /// The network manager object that handles the network requests
    let networkManager: NetworkManager

    /// The environment which is used for all network requests
    public var environment: Environment = .production

    /// The delegate object to receive update events
    public weak var delegate: SnabblePayDelegate?

    /// Identifier for you project
    public var apiKey: String {
        networkManager.authenticator.apiKey
    }

    /// `URLSession` which is used for all network requests
    public var urlSession: URLSession {
        networkManager.urlSession
    }

    /// An array of type-erasing cancellable objects
    var cancellables = Set<AnyCancellable>()

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
        self.networkManager = NetworkManager(
            apiKey: apiKey,
            credentials: credentials?.toDTO(),
            urlSession: urlSession
        )
        self.networkManager.delegate = self
    }
}

// MARK: Combine
extension SnabblePay {

    /// A publisher to update the `Customer`
    /// - Parameters:
    ///   - id: customer id in your database
    ///   - loyaltyId: loyalty id could be a customer card number
    /// - Returns: An AnyPublisher wrapping a customer
    public func updateCustomer(withId id: String?, loyaltyId: String?) -> AnyPublisher<Customer, SnabblePay.Error> {
        let endpoint = Endpoints.Customer.put(id: id, loyaltyId: loyaltyId, onEnvironment: environment)
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Delete customer information
    /// - Returns: An AnyPublisher wrapping the deleted customer
    public func deleteCustomer() -> AnyPublisher<Customer, SnabblePay.Error> {
        let endpoint = Endpoints.Customer.delete(onEnvironment: environment)
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// A publisher that wraps an `Account.Check`
    /// - Parameters:
    ///   - appUri: Callback URLScheme to inform the app that the process is completed
    ///   - city: The city of residence
    ///   - countryCode: The countryCode [PayOne - ISO 3166](https://docs.payone.com/pages/releaseview.action?pageId=1213959) of residence
    /// - Returns: An AnyPublisher wrapping an account check
    /// - Important: A list of supported two letter country codes from ISO 3166 can be found here: https://docs.payone.com/pages/releaseview.action?pageId=1213959
    public func accountCheck(withAppUri appUri: URL, city: String, countryCode: String) -> AnyPublisher<Account.Check, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.check(
            appUri: appUri,
            city: city,
            countryCode: countryCode,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// A publisher thar wraps an `Account` array
    /// - Returns: An AnyPublisher wrapping a list of accounts
    public func accounts() -> AnyPublisher<[Account], SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.get(
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Receive an `Account` Publisher or an error if no account can be found with the given `Account.ID`
    /// - Parameter id: The id of the account you are looking for.
    /// - Returns: An AnyPublisher wrapping an account
    public func account(withId id: Account.ID) -> AnyPublisher<Account, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.get(
            id: id.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Delete the account associated with the given `Account.ID`
    /// - Parameter id: The id of the account you want to delete
    /// - Returns: An AnyPublisher wrapping the deleted account
    public func deleteAccount(withId id: Account.ID) -> AnyPublisher<Account, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.delete(
            id: id.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Create a new mandate for the given `Account.ID`
    ///
    /// - Parameter accountId: The id of the account your want to use
    /// - Returns: An AnyPublisher wrapping a mandate
    ///
    /// -  The `mandateState` of the given account must be `pending` or `declined`
    public func createMandate(forAccountId accountId: Account.ID) -> AnyPublisher<Account.Mandate, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.Mandate.post(
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Returns the current mandate of the given `Account.ID`
    /// - Parameter accountId: The id of the account to the mandate
    /// - Returns: An AnyPublisher wrapping a mandate
    public func mandate(forAccountId accountId: Account.ID) -> AnyPublisher<Account.Mandate, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.Mandate.get(
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Accepts a mandate
    /// - Parameters:
    ///   - mandateId: The id of the to accepted mandate
    ///   - accountId: The id of the account linked to the mandate
    /// - Returns: An AnyPublisher wrapping a mandate
    ///
    /// - The state of the mandate has to be `pending`
    public func acceptMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID) -> AnyPublisher<Account.Mandate, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.Mandate.accept(
            mandateId: mandateId.rawValue,
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Declines a mandate
    /// - Parameters:
    ///   - mandateId: The id of the to accepted mandate
    ///   - accountId: The id of the account linked to the mandate
    /// - Returns: An AnyPublisher wrapping a mandate
    ///
    /// - The state of the mandate has to be `pending`
    public func declineMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID) -> AnyPublisher<Account.Mandate, SnabblePay.Error> {
        let endpoint = Endpoints.Accounts.Mandate.decline(
            mandateId: mandateId.rawValue,
            forAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// List of all sessions for the associated user
    /// - Returns: An AnyPublisher wrapping a list of sessions
    public func sessions() -> AnyPublisher<[Session], SnabblePay.Error> {
        let endpoint = Endpoints.Session.get(
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Start a new session
    /// - Parameter accountId: The id of the account you want to use for the session
    /// - Returns: An AnyPublisher wrapping a new `Session`
    public func startSession(withAccountId accountId: Account.ID) -> AnyPublisher<Session, SnabblePay.Error> {
        let endpoint = Endpoints.Session.post(
            withAccountId: accountId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Refresh a token of a session
    /// - Parameter sessionId: The id of the session which needs to refresh its token
    /// - Returns: An AnyPublisher wrapping a `Session.Token`
    public func refreshToken(withSessionId sessionId: Session.ID) -> AnyPublisher<Session.Token, SnabblePay.Error> {
        let endpoint = Endpoints.Session.Token.post(
            sessionId: sessionId.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Looking for a session with a specific id
    /// - Parameter id: The id of the session you are looking for
    /// - Returns: An AnyPublisher wrapping a `Session`
    public func session(withId id: Session.ID) -> AnyPublisher<Session, SnabblePay.Error> {
        let endpoint = Endpoints.Session.get(
            id: id.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Delete the session associated with the given id
    /// - Parameter id: The id of the session you want to delete
    /// - Returns: An AnyPublisher wrapping the deleted account
    public func deleteSession(withId id: Session.ID) -> AnyPublisher<Session, SnabblePay.Error> {
        let endpoint = Endpoints.Session.delete(
            id: id.rawValue,
            onEnvironment: environment
        )
        return networkManager.publisher(for: endpoint)
            .map { $0.toModel() }
            .mapError { $0.toModel() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
