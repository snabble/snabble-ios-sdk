//
//  AccountViewController.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK
import SwiftUI

final class AccountViewController: DynamicViewController {
    override init(viewModel: DynamicViewModel) {
        super.init(viewModel: viewModel)

        title = NSLocalizedString("profile", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profile-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profile-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

extension AccountViewController: DynamicViewControllerDelegate {
    func dynamicStackViewController(_ viewController: DynamicViewController, tappedWidget widget: SnabbleSDK.Widget, userInfo: [String: Any]?) {
        print(#function)
        print("widget:", widget.id)
        print("userInfo:", userInfo ?? [:])

        switch widget.type {
        case .navigation:
            if let widget = widget as? WidgetNavigation {
                let url = Bundle.main.url(forResource: widget.resource, withExtension: nil)
                let webViewController = WebViewController(url: url!)
                webViewController.title = NSLocalizedString(widget.text, comment: "")
                navigationController?.pushViewController(webViewController, animated: true)
            }
        default:
            break
        }
        
        switch widget.id {
        case "Profile.lastPurchases", "Profile.paymentMethods", "Profile.customerCard":
            let viewController = UIHostingController(rootView: PlaceholderView(title: Asset.localizedString(forKey: widget.id)))
            navigationController?.pushViewController(viewController, animated: true)

        default:
            break
        }
    }    
}

struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .navigationTitle(title)
    }
}
