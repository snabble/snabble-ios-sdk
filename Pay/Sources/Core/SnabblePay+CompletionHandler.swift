//
//  SnabblePay+CompletionHandler.swift
//  
//
//  Created by Andreas Osberghaus on 2023-03-07.
//

import UIKit
import Tagged

extension SnabblePay {
    public func accountCheck(withAppUri appUri: URL, city: String, countryCode: String, completionHandler: @escaping (Result<Account.Check, SnabblePay.Error>) -> Void) {
        accountCheck(withAppUri: appUri, city: city, countryCode: countryCode)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func accounts(completionHandler: @escaping (Result<[Account], SnabblePay.Error>) -> Void) {
        accounts()
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func account(withId id: Account.ID, completionHandler: @escaping (Result<Account, SnabblePay.Error>) -> Void) {
        account(withId: id)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func deleteAccount(withId id: Account.ID, completionHandler: @escaping (Result<Account, SnabblePay.Error>) -> Void) {
        deleteAccount(withId: id)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func createMandate(forAccountId accountId: Account.ID, completionHandler: @escaping (Result<Account.Mandate, SnabblePay.Error>) -> Void) {
        createMandate(forAccountId: accountId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func mandate(forAccountId accountId: Account.ID, completionHandler: @escaping (Result<Account.Mandate, SnabblePay.Error>) -> Void) {
        mandate(forAccountId: accountId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func acceptMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID, completionHandler: @escaping (Result<Account.Mandate, SnabblePay.Error>) -> Void) {
        acceptMandate(withId: mandateId, forAccountId: accountId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func declineMandate(withId mandateId: Account.Mandate.ID, forAccountId accountId: Account.ID, completionHandler: @escaping (Result<Account.Mandate, SnabblePay.Error>) -> Void) {
        declineMandate(withId: mandateId, forAccountId: accountId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func sessions(completionHandler: @escaping (Result<[Session], SnabblePay.Error>) -> Void) {
        sessions()
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func startSession(withAccountId accountId: Account.ID, completionHandler: @escaping (Result<Session, SnabblePay.Error>) -> Void) {
        startSession(withAccountId: accountId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func refreshToken(withSessionId sessionId: Session.ID, completionHandler: @escaping (Result<Session.Token, SnabblePay.Error>) -> Void) {
        refreshToken(withSessionId: sessionId)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func session(withId id: Session.ID, completionHandler: @escaping (Result<Session, SnabblePay.Error>) -> Void) {
        session(withId: id)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }

    public func deleteSession(withId id: Session.ID, completionHandler: @escaping (Result<Session, SnabblePay.Error>) -> Void) {
        deleteSession(withId: id)
            .sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            } receiveValue: {
                completionHandler(.success($0))
            }
            .store(in: &cancellables)
    }
}
