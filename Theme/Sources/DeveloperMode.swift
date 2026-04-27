//
//  DeveloperMode.swift
//  
//
//  Created by Uwe Tilemann on 10.11.22.
//

import UIKit
import SnabbleCore
import KeychainAccess
import SnabbleAssetProviding

public enum DeveloperMode {
    
    public enum Keys: String {
        case activation = "io.snabble.developerMode"
        case checkInShop = "io.snabble.checkInShopId"
        case environment = "io.snabble.environment"

        public var value: Any? {
            return UserDefaults.standard.value(forKey: self.rawValue)
        }
        
        public func remove() {
            UserDefaults.standard.removeObject(forKey: self.rawValue)
        }
    }
    
    public static var isEnabled: Bool {
        return UserDefaults.standard.developerMode
    }
}

public extension UserDefaults {
    @objc
    var developerMode: Bool {
        get {
            return bool(forKey: DeveloperMode.Keys.activation.rawValue)
        }
        set {
            set(newValue, forKey: DeveloperMode.Keys.activation.rawValue)
        }
    }
}

public extension DeveloperMode {
    static var showCheckIn: Bool {
        return Self.isEnabled || BuildConfig.debug
    }
}

public extension DeveloperMode {
    static func environment(for string: String) -> Snabble.Environment? {
        
        if let env = Snabble.Environment(rawValue: string) {
            return env
        }
        if let last = string.components(separatedBy: ".").last, let env = Snabble.Environment(rawValue: last) {
            return env
        }
        return nil
    }
    
    static var environmentMode: Snabble.Environment {
        guard let value = Self.Keys.environment.value as? String, let env = environment(for: value) else {
            return BuildConfig.debug ? .staging : .production
        }
        return env
    }
    static func setEnvironmentMode(_ mode: Snabble.Environment) {
        UserDefaults.standard.set("\(mode.rawValue)", forKey: Self.Keys.environment.rawValue)

    }
}

import SwiftUI

public extension DeveloperMode {
    @MainActor
    static func toggle() {
        if Self.isEnabled == false {
            ask()
        } else {
            UserDefaults.standard.developerMode = false
            print("DeveloperMode is off")
        }
    }

    @MainActor
    static private func ask() {
        guard Self.isEnabled == false else { return }

        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Password", preferredStyle: .alert)
        alert.addTextField { textfield in
            textfield.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""

            var password = Asset.localizedString(forKey: "SnabbelDeveloperPassword")
            if password == "SnabbelDeveloperPassword" {
                password = "Snabble"
            }
            if let magicData = password.data(using: .utf8),
               let inputData = text.data(using: .utf8),
               magicData.base64EncodedData() == inputData.base64EncodedData() {
                UserDefaults.standard.developerMode = true
                print("DeveloperMode is on")
            }
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel))
        rootVC.present(alert, animated: true)
    }
}
