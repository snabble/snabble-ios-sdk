//
//  SnabblePay+Error.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-27.
//

import Foundation
import SnabblePayNetwork

extension SnabblePay {
    /// Public snabble pay error
    public enum Error: Swift.Error {
        /// Invalid request, e.g. invalid URL
        case invalidRequestError(String)

        /// Indicates an error on the transport layer, e.g. not being able to connect to the server
        case transportError(URLError)

        /// Received an invalid response, e.g. non-HTTP result
        case invalidResponse(URLResponse)

        /// Server-side validation error
        case validationError(ValidationError)

        /// The server sent data in an unexpected format
        case decodingError(DecodingError)

        /// Unexpected error within the flow
        case unexpected(Swift.Error)
    }
}

extension APIError: ToModel {
    func toModel() -> SnabblePay.Error {
        switch self {
        case .invalidRequestError(let details):
            return .invalidRequestError(details)
        case .transportError(let urlError):
            return .transportError(urlError)
        case .invalidResponse(let urlResponse):
            return .invalidResponse(urlResponse)
        case .validationError(_, let error):
            return .validationError(error.toModel())
        case .decodingError(let decodingError):
            return .decodingError(decodingError)
        case .unexpected(let error):
            return .unexpected(error)
        }
    }
}

/// Validation error on the server
public struct ValidationError {
    /// Defined error cause
    public let reason: Reason
    /// Optional hint to understand the error
    public let message: String?

    /// Known validation error reasons
    public enum Reason: String, Decodable {
        /// Internal Server Error
        case internalError = "internal_error"
        /// Unauthorized
        case unauthorized = "unauthorized"
        /// User not found
        case userNotFound = "user_not_found"
        /// Token not found
        case tokenNotFound = "token_not_found"
        /// Account not found
        case accountNotFound = "account_not_found"
        /// Session not found
        case sessionNotFound = "session_not_found"
        /// Transaction not found
        case transactionNotFound = "transaction_not_found"
        /// Customer not found
        case customerNotFound = "customer_not_found"
        /// Mandate not found
        case mandateNotFound = "mandate_not_found"
        /// Validation Error
        case validationError = "validation_error"
        /// Session token has expired
        case sessionTokenExpired = "session_token_expired"
        /// Mandates has not yet been accepted
        case mandateNotAccepted = "mandate_not_accepted"
        /// Invalid session state
        case invalidSessionState = "invalid_session_state"
        /// Invalid status for the transaction
        case invalidTransactionState = "invalid_transaction_state"
        /// Session already has a transaction
        case sessionHasTransaction = "session_has_transaction"
        /// Transaction has already started
        case transactionAlreadyStarted = "transaction_already_started"
        /// Can not start transaction with locale mandate
        case localMandate = "local_mandate"
        /// Unknown error (maybe you have to update the SDK)
        case unknown
    }
}

extension ValidationError: FromDTO {
    init(fromDTO dto: Endpoints.Error) {
        reason = dto.reason.toModel()
        message = dto.message
    }
}

extension Endpoints.Error: ToModel {
    func toModel() -> ValidationError {
        .init(fromDTO: self)
    }
}

extension Endpoints.Error.Reason: ToModel {
    // swiftlint:disable:next cyclomatic_complexity
    func toModel() -> ValidationError.Reason {
        switch self {
        case .internalError:
            return .internalError
        case .unauthorized:
            return .unauthorized
        case .userNotFound:
            return .userNotFound
        case .tokenNotFound:
            return .tokenNotFound
        case .accountNotFound:
            return .accountNotFound
        case .sessionNotFound:
            return .sessionNotFound
        case .transactionNotFound:
            return .transactionNotFound
        case .customerNotFound:
            return .customerNotFound
        case .mandateNotFound:
            return .mandateNotFound
        case .validationError:
            return .validationError
        case .sessionTokenExpired:
            return .sessionTokenExpired
        case .mandateNotAccepted:
            return .mandateNotAccepted
        case .invalidSessionState:
            return .invalidSessionState
        case .invalidTransactionState:
            return .invalidTransactionState
        case .sessionHasTransaction:
            return .sessionHasTransaction
        case .transactionAlreadyStarted:
            return .transactionAlreadyStarted
        case .localMandate:
            return .localMandate
        case .unknown:
            return .unknown
        }
    }
}
