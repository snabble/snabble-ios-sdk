//
//  Publisher+RetryOnceIfDoBefore.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-27.
//

import Foundation
import Combine

extension Publishers {
    struct RetryOnceIf<P: Publisher>: Publisher {
        typealias Output = P.Output
        typealias Failure = P.Failure

        let publisher: P
        let times: Int
        let condition: (P.Failure) -> Bool
        let doBefore: () -> Void

        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            guard times > 0 else {
                return publisher.receive(subscriber: subscriber)
            }

            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error) {
                    doBefore()
                    return RetryOnceIf(
                        publisher: publisher,
                        times: times - 1,
                        condition: condition,
                        doBefore: doBefore
                    ).eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
                .receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    func retryOnce(if condition: @escaping (Failure) -> Bool, doBefore: @escaping () -> Void) -> Publishers.RetryOnceIf<Self> {
        Publishers.RetryOnceIf(publisher: self, times: 1, condition: condition, doBefore: doBefore)
    }
}
