//
//  DeveloperMode.swift
//  
//
//  Created by Uwe Tilemann on 10.11.22.
//

import UIKit
import SnabbleCore
import KeychainAccess

extension CheckInManager {
    static let developerCheckInKey = "io.snabble.checkInShopId"
    
    func shop(for provider: ShopProviding) -> Shop? {
        return projects
            .flatMap({ $0.shops })
            .first(where: { $0.id == provider.id })
    }
    
    func isCheckedIn(for provider: ShopProviding) -> Bool {
        return shop?.id == provider.id
    }
    
    public func verifyDeveloperCheckin() {
        if DeveloperMode.showCheckIn, let checkInShopId = UserDefaults.standard.string(forKey: Self.developerCheckInKey) {
            if let shop = projects
                .flatMap({ $0.shops })
                .first(where: { "\($0.id)" == checkInShopId }) {
                developerCheckin(at: shop)
            }
        }
    }

    func developerCheckin(at fakeShop: ShopProviding, persist: Bool = false) {
        if persist {
            UserDefaults.standard.set("\(fakeShop.id)", forKey: Self.developerCheckInKey)
        }
        stopUpdating()
        shop = shop(for: fakeShop)
    }

    func developerCheckout() {
        UserDefaults.standard.removeObject(forKey: Self.developerCheckInKey)

        shop = nil
        startUpdating()
    }
}

public enum DeveloperMode {
    
    public enum Keys: String {
        case activation = "io.snabble.developerMode"
        case environment = "io.snabble.environment"

        var value: Any? {
            return UserDefaults.standard.value(forKey: self.rawValue)
        }
    }
    
    static var isEnabled: Bool {
        let isEnabled = UserDefaults.standard.bool(forKey: Self.Keys.activation.rawValue)
        
        if isEnabled {
            
        }
        return isEnabled
    }
}

public extension DeveloperMode {
    static func toggle() {
        if Self.isEnabled == false {
            ask()
        } else {
            UserDefaults.standard.set(false, forKey: Self.Keys.activation.rawValue)
            print("DeveloperMode is off")
        }
    }
    
    static private func ask() {
        guard Self.isEnabled == false else {
            return
        }
        let alert = AlertView(title: nil, message: "Password")

        alert.alertController?.addTextField { textfield in
            textfield.isSecureTextEntry = true
        }
        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
            let text = alert.alertController?.textFields?.first?.text ?? ""

            let magicWord = Asset.localizedString(forKey: "Snabble").lowercased().data(using: .utf8)!.base64EncodedString()
            let base64 = text.lowercased().data(using: .utf8)!.base64EncodedString()
            if base64 == magicWord {
                UserDefaults.standard.set(true, forKey: Self.Keys.activation.rawValue)
                print("DeveloperMode is on")
            }
            alert.dismiss(animated: false)
        })
        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
            alert.dismiss(animated: false)
        }))
        
        alert.show()
    }
}

public extension DeveloperMode {
    static var showCheckIn: Bool {
        return Self.isEnabled || BuildConfig.debug
    }

    static func toggleCheckIn(for shop: ShopProviding) {
        guard showCheckIn else {
            return
        }

        if Snabble.shared.checkInManager.isCheckedIn(for: shop) {
            Snabble.shared.checkInManager.developerCheckout()
        } else {
            let alert = AlertView(title: "Check in", message: nil)

            alert.alertController?.addAction(UIAlertAction(title: "This session", style: .default) { _ in
                Snabble.shared.checkInManager.developerCheckin(at: shop, persist: false)
                alert.dismiss(animated: false)
            })

            alert.alertController?.addAction(UIAlertAction(title: "Until next check out", style: .default) { _ in
                Snabble.shared.checkInManager.developerCheckin(at: shop, persist: true)
                alert.dismiss(animated: false)
            })

            alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
                alert.dismiss(animated: false)
            }))
        
            alert.show()
        }
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

public extension DeveloperMode {
    
    static func resetAppId(viewController: DynamicViewController) {
        let alert = UIAlertController(title: "Create new app user id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
            Snabble.shared.appUserId = nil
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    static func resetClientId(viewController: DynamicViewController) {
        let alert = UIAlertController(title: "Create new client id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: "Snabble.api.clientId")
            let keychain = Keychain(service: "io.snabble.sdk")
            keychain["Snabble.api.clientId"] = nil
            _ = Snabble.clientId
            Snabble.shared.appUserId = nil
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    static func switchEnvironment(environment: Snabble.Environment, model: MultiValueViewModel, viewController: DynamicViewController) {
        
        if Snabble.shared.environment != environment {
            print("will switch environment to \(environment)")
            
            let alert = UIAlertController(title: "Clean Restart required", message: "Delete all databases and restart app?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                self.setEnvironmentMode(environment)
                                
//                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
//                for project in Snabble.shared.projects {
//                    let db = appSupport.appendingPathComponent(project.id.rawValue, isDirectory: true).appendingPathComponent("products.sqlite3")
//                    try? FileManager.default.removeItem(at: db)
//                }
//                Defaults.reset(.autoCheckinShop)
//                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
//
//                ProjectSwitcher.syncAndExit(message: "Switching servers...", wait: 1)
            })
            alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
                self.setEnvironmentMode(Snabble.shared.environment)
                model.selectedValue = "io.snabble.environment." + Snabble.shared.environment.rawValue
            })
            
            viewController.present(alert, animated: true)
        }
    }
}
