//
//  AccountViewController.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK

final class AccountViewController: SnabbleSDK.ProfileViewController {

    override init(viewModel: DynamicStackViewModel) {
        super.init(viewModel: viewModel)

        title = NSLocalizedString("Sample.account", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profil-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profil-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
