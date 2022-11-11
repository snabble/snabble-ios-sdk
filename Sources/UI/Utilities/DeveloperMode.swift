//
//  DeveloperMode.swift
//  
//
//  Created by Uwe Tilemann on 10.11.22.
//

import SnabbleCore
import UIKit

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

class AlertView {
    private var window: UIWindow?
    public var alertController: UIAlertController?
    private var presentingViewController: ClearViewController
    
    init(title: String?, message: String?) {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.presentingViewController = ClearViewController()
        self.window?.rootViewController = self.presentingViewController
        self.window?.windowLevel = UIWindow.Level.alert + 1
        
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    
    func show() {
        if let alertController = alertController {
            DispatchQueue.main.async {
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func addAction(_ action: UIAlertAction) {
        if let alertController = alertController {
            alertController.addAction(action)
        }
    }
    
    func addCancelButton(string: String) {
        if let alertController = alertController {
            alertController.addAction(UIAlertAction(title: string, style: .cancel, handler: nil))
        }
    }
    func dismiss(animated: Bool) {
        DispatchQueue.main.async {
            self.window?.rootViewController?.dismiss(animated: animated, completion: nil)
            self.window?.rootViewController = nil
            self.window?.isHidden = true
            UIApplication.shared.windows.first!.makeKeyAndVisible()
            self.window = nil
            self.alertController = nil
        }
    }
}

// In the case of view controller-based status bar style, make sure we use the same style for our view controller
private class ClearViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
        return view.window?.windowScene?.statusBarManager?.statusBarStyle ?? .default
    }

    fileprivate override var prefersStatusBarHidden: Bool {
        return view.window?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
    }
}

public enum DeveloperMode {
    
    static let key = "io.snabble.developerMode"
    
    static var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Self.key)
    }
    
    static func toggle() {
        if Self.isEnabled == false {
            ask()
        } else {
            UserDefaults.standard.set(false, forKey: Self.key)
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

            let magicWord = "c25hYmJsZXJ1bHo="
            let base64 = text.lowercased().data(using: .utf8)!.base64EncodedString()
            if base64 == magicWord {
                UserDefaults.standard.set(true, forKey: Self.key)
                print("DeveloperMode is on")
            }
            alert.dismiss(animated: false)
        })
        alert.alertController?.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
            alert.dismiss(animated: false)
        }))
        
        alert.show()
    }
    
    public static func config(for string: String) -> Snabble.Environment? {
        
        if let env = Snabble.Environment(rawValue: string) {
            return env
        }
        if let last = string.components(separatedBy: ".").last, let env = Snabble.Environment(rawValue: last) {
            return env
        }
        return nil
    }
    
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
