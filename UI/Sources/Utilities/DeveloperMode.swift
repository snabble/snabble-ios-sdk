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

extension CheckInManager {
    func shop(for provider: ShopProviding) -> Shop? {
        return projects
            .flatMap({ $0.shops })
            .first(where: { $0.id == provider.id })
    }
    
    func isCheckedIn(for provider: ShopProviding) -> Bool {
        return shop?.id == provider.id
    }
    
    public func verifyDeveloperCheckin() {
        if DeveloperMode.showCheckIn, let checkInShopId = UserDefaults.standard.string(forKey: DeveloperMode.Keys.checkInShop.rawValue) {
            if let shop = projects
                .flatMap({ $0.shops })
                .first(where: { "\($0.id)" == checkInShopId }) {
                developerCheckin(at: shop)
            }
        }
    }

    func developerCheckin(at fakeShop: ShopProviding, persist: Bool = false) {
        if persist {
            UserDefaults.standard.set("\(fakeShop.id)", forKey: DeveloperMode.Keys.checkInShop.rawValue)
        }
        stopUpdating()
        shop = shop(for: fakeShop)
    }

    func developerCheckout() {
        UserDefaults.standard.removeObject(forKey: DeveloperMode.Keys.checkInShop.rawValue)

        shop = nil
        startUpdating()
    }
}

public enum DeveloperMode {
    
    public enum Keys: String {
        case activation = "io.snabble.developerMode"
        case checkInShop = "io.snabble.checkInShopId"
        case environment = "io.snabble.environment"

        var value: Any? {
            return UserDefaults.standard.value(forKey: self.rawValue)
        }
        
        func remove() {
            UserDefaults.standard.removeObject(forKey: self.rawValue)
        }
    }
    
    static var isEnabled: Bool {
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
        guard Self.isEnabled == false else {
            return
        }
        let alert = AlertView(title: nil, message: "Password")

        alert.alertController?.addTextField { textfield in
            textfield.isSecureTextEntry = true
        }
        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
            let text = alert.alertController?.textFields?.first?.text ?? ""

            var password = Asset.localizedString(forKey: "SnabbelDeveloperPassword")
            if password == "SnabbelDeveloperPassword" {
                password = "Snabble"
            }
            if let magicData = password.data(using: .utf8),
               let inputData = text.data(using: .utf8) {
                
                if magicData.base64EncodedData() == inputData.base64EncodedData() {
                    UserDefaults.standard.developerMode = true
                    print("DeveloperMode is on")
                }
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

    @MainActor
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
    
    @MainActor
    static func resetAppId(viewController: DynamicViewController) {
        let alert = UIAlertController(title: "Create new app user id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
            Snabble.shared.appUser = nil
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    @MainActor
    static func resetClientId(viewController: DynamicViewController) {
        let alert = UIAlertController(title: "Create new client id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: "Snabble.api.clientId")
            let keychain = Keychain(service: "io.snabble.sdk")
            keychain["Snabble.api.clientId"] = nil
            _ = Snabble.clientId
            Snabble.shared.appUser = nil
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    @MainActor
    static func switchEnvironment(environment: Snabble.Environment, model: MultiValueViewModel, viewController: DynamicViewController) {
        
        if Snabble.shared.environment != environment {
            print("will switch environment to \(environment)")
            
            let alert = UIAlertController(title: "Clean Restart required", message: "Delete all databases and restart app?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                                
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

                do {
                    for project in Snabble.shared.projects {
                        let db = appSupport.appendingPathComponent(project.id.rawValue, isDirectory: true).appendingPathComponent("products.sqlite3")
                        
                        if FileManager.default.fileExists(atPath: db.path) {
                            print("remove db at: \(db)")
                            try FileManager.default.removeItem(at: db)
                        }
                    }
                    self.setEnvironmentMode(environment)
                    DeveloperMode.Keys.checkInShop.remove()
                    
                    UserDefaults.standard.synchronize()
                    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        exit(0)
                    }
                } catch {
                    print(error)
                    
                    self.setEnvironmentMode(Snabble.shared.environment)
                    model.selectedValue = "io.snabble.environment." + Snabble.shared.environment.rawValue
                }
            })
            alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
                self.setEnvironmentMode(Snabble.shared.environment)
                model.selectedValue = "io.snabble.environment." + Snabble.shared.environment.rawValue
            })
            
            viewController.present(alert, animated: true)
        }
    }
}
