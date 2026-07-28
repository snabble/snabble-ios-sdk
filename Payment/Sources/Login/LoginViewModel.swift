//
//  LoginViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 13.10.22.
//

import Foundation
import Observation

import SnabbleAssetProviding

@MainActor
public protocol Loginable {
    var username: String? { get set }
    var password: String? { get set }

    /// returns true if username and password successfully passed validation
    var isValid: Bool { get set }

    /// set an individual error message if login fails
    var errorMessage: String? { get set }

    /// consume this stream to start your login process
    var actionStream: AsyncStream<[String: Any]?> { get }
}

public enum LoginError: Error {
    case loginFailed
}

public enum LoginStrings: String {
    case info = "message"
    case login
    case username
    case password
    case usernameIsEmpty
    case passwordIsEmpty
    case usernameAndPasswordIsEmpty

    public func localizedString(_ string: String? = nil) -> String {
        if let prefix = string {
            let key = prefix + "." + self.rawValue

            return Asset.localizedString(forKey: key)
        } else {
            return Asset.localizedString(forKey: "Snabble.Login.\(self.rawValue)")
        }
    }
}

@Observable
@MainActor
public class LoginViewModel: Loginable {
    public var username: String? {
        didSet { scheduleValidation() }
    }
    public var password: String? {
        didSet { scheduleValidation() }
    }
    public var isValid = false {
        didSet {
            if errorMessage != nil {
                self.errorMessage = nil
            }
        }
    }

    // output
    public var hintMessage: String?
    public var errorMessage: String?

    public var debounce: TimeInterval = 0.5
    public var minimumInputCount: Int = 4

    @ObservationIgnored public private(set) var actionStream: AsyncStream<[String: Any]?>
    @ObservationIgnored private var actionContinuation: AsyncStream<[String: Any]?>.Continuation?
    @ObservationIgnored private var validationTask: Task<Void, Never>?

    public enum Action: String {
        case login
        case save
        case remove
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

    public func send(_ action: sending [String: Any]?) {
        actionContinuation?.yield(action)
    }

    private func scheduleValidation() {
        validationTask?.cancel()
        let delay = debounce
        let minCount = minimumInputCount
        validationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let usernameValid = (self.username?.count ?? 0) >= minCount
            let passwordValid = self.password != nil
            if !usernameValid && !passwordValid {
                self.hintMessage = LoginStrings.usernameAndPasswordIsEmpty.localizedString()
            } else if !usernameValid {
                self.hintMessage = LoginStrings.usernameIsEmpty.localizedString()
            } else if !passwordValid {
                self.hintMessage = LoginStrings.passwordIsEmpty.localizedString()
            } else {
                self.hintMessage = ""
            }
            self.isValid = usernameValid && passwordValid
        }
    }
}
