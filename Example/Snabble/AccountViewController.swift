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
            DeveloperMode.resetAppId(viewController: viewController)
            
        case "Profile.resetClientID":
            DeveloperMode.resetClientId(viewController: viewController)

        case "io.snabble.environment":
            if let value = userInfo?["value"] as? String, let model = userInfo?["model"] as? MultiValueViewModel, let env = DeveloperMode.environment(for: value) {
                DeveloperMode.switchEnvironment(environment: env, model: model, viewController: viewController)
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
