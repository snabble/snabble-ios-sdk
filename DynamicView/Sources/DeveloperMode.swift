//
//  DeveloperMode.swift
//  
//
//  Created by Uwe Tilemann on 10.11.22.
//

@preconcurrency import UIKit

import SnabbleCore
import SnabbleUser
import KeychainAccess
import SnabbleAssetProviding
import SnabbleTheme

// public extension DeveloperMode {
//    @MainActor
//    static func toggle() {
//        if Self.isEnabled == false {
//            ask()
//        } else {
//            UserDefaults.standard.developerMode = false
//            print("DeveloperMode is off")
//        }
//    }
//    
//    @MainActor
//    static private func ask() {
//        guard Self.isEnabled == false else {
//            return
//        }
//        let alert = AlertView(title: nil, message: "Password")
//
//        alert.alertController?.addTextField { textfield in
//            textfield.isSecureTextEntry = true
//        }
//        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .default) { _ in
//            let text = alert.alertController?.textFields?.first?.text ?? ""
//
//            var password = Asset.localizedString(forKey: "SnabbelDeveloperPassword")
//            if password == "SnabbelDeveloperPassword" {
//                password = "Snabble"
//            }
//            if let magicData = password.data(using: .utf8),
//               let inputData = text.data(using: .utf8) {
//                
//                if magicData.base64EncodedData() == inputData.base64EncodedData() {
//                    UserDefaults.standard.developerMode = true
//                    print("DeveloperMode is on")
//                }
//            }
//            alert.dismiss(animated: false)
//        })
//        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
//            alert.dismiss(animated: false)
//        }))
//        
//        alert.show()
//    }
// }
//
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
