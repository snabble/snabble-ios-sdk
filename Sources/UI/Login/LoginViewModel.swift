//
//  LoginViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 13.10.22.
//

import Foundation
import Combine

public protocol Loginable {
    var username: String { get set }
    var password: String { get set }
    
    /// return true if username and password successfully passed validation
    var isValid: Bool { get }

    /// set an individual error message, if login fails
    var errorMessage: String { get set }
    
    /// subscribe to this Publisher to start your login process
    var actionPublisher: PassthroughSubject<Void, Never> { get }
}

public enum LoginError: Error {
    case loginFailed
}

public enum LoginStrings: String {
    case login
    case username
    case password
    case usernameIsEmpty
    case passwordIsEmpty
    case usernameAndPasswordIsEmpty
    
    public var localizedString: String {
        return Asset.localizedString(forKey: "Login.\(self.rawValue)")
    }
}

public class LoginViewModel: Loginable, ObservableObject {
    @Published public var username: String = ""
    @Published public var password: String = ""
    @Published public var isValid = false {
        didSet {
            if errorMessage.isEmpty == false {
                self.errorMessage = ""
            }
        }
    }
    
    // output
    @Published public var hintMessage = ""
    @Published public var errorMessage: String = ""

    public var debounce: RunLoop.SchedulerTimeType.Stride = 0.5
    public var minimumInputCount: Int = 3
    
    private var cancellables = Set<AnyCancellable>()

    private var isUsernameValidPublisher: AnyPublisher<Bool, Never> {
        $username
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimum(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    private var isPasswordValidPublisher: AnyPublisher<Bool, Never> {
        $password
            .debounce(for: debounce, scheduler: RunLoop.main)
            .map { !$0.isEmpty }
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
    
    /// Emits if the login button is tapped
    public let actionPublisher = PassthroughSubject<Void, Never>()

    init() {
        isUsernameValidPublisher
            .combineLatest(isPasswordValidPublisher)
            .map { validUsername, validPassword in
                if !validUsername && !validPassword {
                    return LoginStrings.usernameAndPasswordIsEmpty.localizedString
                } else if !validUsername {
                    return LoginStrings.usernameIsEmpty.localizedString
                } else if !validPassword {
                    return LoginStrings.passwordIsEmpty.localizedString
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
