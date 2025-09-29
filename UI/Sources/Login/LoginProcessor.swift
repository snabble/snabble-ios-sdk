//
//  LoginProcessor.swift
//  Snabble
//
//  Created by Uwe Tilemann on 16.10.22.
//

import Foundation
import Combine

@MainActor
protocol LoginProcessing {
    var loginModel: Loginable? { get }

    func login()
    func save() async throws
    func remove()
}
