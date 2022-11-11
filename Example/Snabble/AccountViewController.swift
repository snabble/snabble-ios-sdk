//
//  AccountViewController.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SwiftUI
import SnabbleUI
import SnabbleCore
import KeychainAccess

final class AccountViewController: DynamicViewController {
    override init(viewModel: DynamicViewModel) {
        super.init(viewModel: viewModel)
        delegate = self

        title = NSLocalizedString("profile", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profile-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profile-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountViewController: DynamicViewControllerDelegate {
    func dynamicStackViewController(_ viewController: DynamicViewController, tappedWidget widget: SnabbleUI.Widget, userInfo: [String: Any]?) {
        print(#function)
        print("widget:", widget.id)
        print("userInfo:", userInfo ?? [:])

        switch widget.type {
        case .navigation:
            if let widget = widget as? WidgetNavigation, let url = Bundle.main.url(forResource: widget.resource, withExtension: nil) {
                // SnabbleSDK provides a SwiftUI WebView
                let webViewController = UIHostingController(rootView: WebView(url: url))
                webViewController.title = NSLocalizedString(widget.text, comment: "")
                navigationController?.pushViewController(webViewController, animated: true)
            }
        default:
            break
        }
        
        switch widget.id {
        case "Profile.lastPurchases":
            let viewController = ReceiptsListViewController(checkoutProcess: nil)
            navigationController?.pushViewController(viewController, animated: true)

        case "Profile.paymentMethods", "Profile.customerCard":
            let viewController = UIHostingController(rootView: PlaceholderView(title: Asset.localizedString(forKey: widget.id)))
            navigationController?.pushViewController(viewController, animated: true)
            
        case "Profile.resetAppID":
            let alert = UIAlertController(title: "Create new app user id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
                Snabble.shared.appUserId = nil
            })
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
        case "Profile.resetClientID":
            let alert = UIAlertController(title: "Create new client id?", message: "You will irrevocably lose all previous orders.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "ok"), style: .destructive) { _ in
                UserDefaults.standard.removeObject(forKey: "Snabble.api.clientId")
                let keychain = Keychain(service: "io.snabble.sdk")
                keychain["Snabble.api.clientId"] = nil
                _ = Snabble.clientId
                Snabble.shared.appUserId = nil
            })
            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
            self.present(alert, animated: true)

        case "io.snabble.environment":
            if let value = userInfo?["value"] as? String, let env = DeveloperMode.config(for: value) {
                print("switch environment to \(env)")
            }
        default:
            break
        }
    }
}

private struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .navigationTitle(title)
    }
}
