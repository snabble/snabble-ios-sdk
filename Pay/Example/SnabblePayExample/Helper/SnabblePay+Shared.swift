//
//  NetworkManager+Shared.swift
//  SnabblePayExample
//
//  Created by Andreas Osberghaus on 2023-01-26.
//

import Foundation
import SnabblePay

extension SnabblePay {
    private static var _shared: SnabblePay?
    
    static var shared: SnabblePay {
        guard _shared == nil else {
            return _shared!
        }
        var credentials: Credentials?
        if let savedPerson = UserDefaults.credentials {
            credentials = try? JSONDecoder().decode(Credentials.self, from: savedPerson)
        }
        let snabblePay: SnabblePay = .init(
            apiKey: "IO2wX69CsqZUQ3HshOnRkO4y5Gy/kRar6Fnvkp94piA2ivUun7TC7MjukrgUKlu7g8W8/enVsPDT7Kvq28ycw==",
            credentials: credentials,
            urlSession: .shared
        )
        snabblePay.environment = .development
        snabblePay.delegate = snabblePay
        _shared = snabblePay
        return snabblePay
    }

    static func reset() {
        UserDefaults.credentials = nil
        UserDefaults.selectedAccount = nil
        
        _shared = nil
    }
}

extension SnabblePay: SnabblePayDelegate {
    public func snabblePay(_ snabblePay: SnabblePay, didUpdateCredentials credentials: Credentials?) {
        if let encoded = try? JSONEncoder().encode(credentials) {
            UserDefaults.credentials = encoded
       } else {
            UserDefaults.credentials = nil
        }
    }
}

extension UserDefaults {
    private enum Keys {
        static let selectedAccount = "account"
        static let credentials = "credentials"
    }

    class var credentials: Data? {
        get {
            UserDefaults.standard.data(forKey: Keys.credentials)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.credentials)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var selectedAccount: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.selectedAccount)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectedAccount)
            UserDefaults.standard.synchronize()
        }
    }
}
