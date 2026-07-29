//
//  PaymentSubjectViewModel.swift
//
//
//  Created by Uwe Tilemann on 30.06.23.
//

import Foundation
import Observation

@Observable
@MainActor
public class PaymentSubjectViewModel {
    public var subject: String? {
        didSet { scheduleValidation() }
    }
    public var isValid: Bool = false

    public var debounce: TimeInterval = 0.5
    public var minimumInputCount: Int = 4

    @ObservationIgnored public private(set) var actionStream: AsyncStream<[String: Any]?>
    @ObservationIgnored private var actionContinuation: AsyncStream<[String: Any]?>.Continuation?
    @ObservationIgnored private var validationTask: Task<Void, Never>?

    public enum Action: String {
        case add
        case skip
        case cancel
    }

    public init() {
        var cont: AsyncStream<[String: Any]?>.Continuation!
        actionStream = AsyncStream { cont = $0 }
        actionContinuation = cont
    }

    deinit {
        actionContinuation?.finish()
        validationTask?.cancel()
    }

    public func add() {
        actionContinuation?.yield(["action": Action.add.rawValue])
    }

    public func skip() {
        actionContinuation?.yield(["action": Action.skip.rawValue])
    }

    public func cancel() {
        actionContinuation?.yield(["action": Action.cancel.rawValue])
    }

    private func scheduleValidation() {
        validationTask?.cancel()
        let delay = debounce
        let minCount = minimumInputCount
        validationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.isValid = (self.subject?.count ?? 0) >= minCount
        }
    }
}
