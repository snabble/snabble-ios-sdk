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
    func save()
    func remove()
}

open class LoginProcessor: LoginProcessing {
    
    public var loginModel: Loginable?

    public init(loginModel: Loginable? = nil) {
        self.loginModel = loginModel
    }

    /// should be overwritten by subclass
    open func login() {
    }
    open func save() {
    }
    open func remove() {
    }
}
