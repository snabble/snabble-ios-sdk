//
//  AccountViewController.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class AccountViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("Sample.account", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profil-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profil-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
