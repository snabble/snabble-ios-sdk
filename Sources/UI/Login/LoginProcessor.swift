//
//  LoginProcessor.swift
//  Snabble
//
//  Created by Uwe Tilemann on 16.10.22.
//

import Foundation
import Combine

protocol LoginProcessing {
    var loginModel: Loginable? { get set }

    func login()
}

open class LoginProcessor: LoginProcessing {
    
    var cancellables = Set<AnyCancellable>()

    public var loginModel: Loginable? {
        didSet {
            loginModel?.actionPublisher
                .sink { [weak self] _ in
                self?.login()
            }
            .store(in: &cancellables)
        }
    }

    public init(loginModel: Loginable? = nil) {
        self.loginModel = loginModel
    }

    /// should be overwritten by subclass
    open func login() {
    }
}
