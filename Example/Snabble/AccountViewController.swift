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

        title = NSLocalizedString("Sample.Profile.title", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profil-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profil-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
