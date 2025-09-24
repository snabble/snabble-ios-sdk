//
//  LoginViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 13.10.22.
//

import Foundation
import Combine
import Observation
import SnabbleAssetProviding

public protocol Loginable {
    var username: String? { get set }
    var password: String? { get set }
    
    /// return true if username and password successfully passed validation
    var isValid: Bool { get set }

    /// set an individual error message, if login fails
    var errorMessage: String? { get set }
    
    /// subscribe to this Publisher to start your login process
    var actionPublisher: PassthroughSubject<[String: Any]?, Never> { get }
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
public class LoginViewModel: Loginable {
    public var username: String? {
        didSet {
            usernameSubject.send(username)
        }
    }
    public var password: String? {
        didSet {
            passwordSubject.send(password)
        }
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

    public var debounce: RunLoop.SchedulerTimeType.Stride = 0.5
    public var minimumInputCount: Int = 4
    
    private var cancellables = Set<AnyCancellable>()

    // Internal publishers for validation - using CurrentValueSubject for @Observable compatibility
    private let usernameSubject = CurrentValueSubject<String?, Never>(nil)
    private let passwordSubject = CurrentValueSubject<String?, Never>(nil)

    private var isUsernameValidPublisher: AnyPublisher<Bool, Never> {
        usernameSubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimumOptional(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    private var isPasswordValidPublisher: AnyPublisher<Bool, Never> {
        passwordSubject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var isFormValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
            .map { usernameIsValid, passwordIsValid in
                usernameIsValid && passwordIsValid
            }
            .eraseToAnyPublisher()
    }
    
    /// Emits if the login button is tapped the action `login`
    /// if a login request was successfull the action `save` is published.
    /// if a remove was successfull the action `remove` is published.
    public let actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    public enum Action: String {
        case login
        case save
        case remove
    }
    
    init() {
        isUsernameValidPublisher
            .combineLatest(isPasswordValidPublisher)
            .map { validUsername, validPassword in
                if !validUsername && !validPassword {
                    return LoginStrings.usernameAndPasswordIsEmpty.localizedString()
                } else if !validUsername {
                    return LoginStrings.usernameIsEmpty.localizedString()
                } else if !validPassword {
                    return LoginStrings.passwordIsEmpty.localizedString()
                }
                return ""
            }
            .assign(to: \LoginViewModel.hintMessage, onWeak: self)
            .store(in: &cancellables)
        
        isFormValidPublisher
            .assign(to: \.isValid, onWeak: self)
            .store(in: &cancellables)
    }
}
