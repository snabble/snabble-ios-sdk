//
//  Autonomo.swift
//
//
//  Created by Andreas Osberghaus on 2023-09-04.
//

import Foundation

public enum Autonomo {
    public enum State: String, Codable {
        case preAuthFailed = "pre_auth_failed"
        case preAuthErrored = "pre_auth_errored"
        case entryPending = "entry_pending"
        case entryDenied = "entry_denied"
        case entryNotPossible = "entry_not_possible"
        case entryTokenInvalid = "entry_token_invalid"
        case clientEntering = "client_entering"
        case clientEntered = "client_entered"
        case clientLeft = "client_left"
        case clientExited = "client_exited"
        case cartCompleted = "cart_completed"
        case cartPaid = "cart_paid"
        case paymentFailed = "payment_failed"
        case failed
    }
    public struct Session: Codable, Identifiable {
        public let id: Identifier<Session>
        public let entryToken: EntryToken?
        public let state: State
        public let customerMessage: String?
    }

    public struct EntryToken: Codable, SnabbleCore.EntryToken {
        public let value: String
        public let validUntil: Date
        public let refreshAfter: Date
    }
}

private struct SessionRequest: Encodable {
    let shopID: String
    let paymentMethod: String
    let paymentOrigin: String
    let numberOfPersons: Int
}

extension Project {
    public func getAutonomoSession(for shop: Shop, paymentMethodDetail: PaymentMethodDetail, numberOfPersons: Int, completion: @escaping (Result<Autonomo.Session, SnabbleError>) -> Void) {
        let tokenRequest = SessionRequest(
            shopID: shop.id.rawValue,
            paymentMethod: paymentMethodDetail.rawMethod.rawValue,
            paymentOrigin: paymentMethodDetail.encryptedData,
            numberOfPersons: numberOfPersons
        )

        guard let data = try? JSONEncoder().encode(tokenRequest) else {
            return completion(.failure(SnabbleError.invalid))
        }

        self.request(.post, "/\(shop.projectId)/autonomo/sessions", body: data, timeout: 5) { request in
            guard let request = request else {
                return completion(.failure(SnabbleError.noRequest))
            }

            self.perform(request, completion)
        }
    }

    public func updateAutonomoSession(for sessionId: Identifier<Autonomo.Session>, projectId: Identifier<Project>, completion: @escaping (Result<Autonomo.Session, SnabbleError>) -> Void) {
        self.request(.get, "/\(projectId.rawValue)/autonomo/sessions/\(sessionId.rawValue)", timeout: 5) { request in
            guard let request = request else {
                return completion(.failure(SnabbleError.noRequest))
            }

            self.perform(request, completion)
        }
    }
}
