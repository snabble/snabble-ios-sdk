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

        title = NSLocalizedString("Sample.profile", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profile-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profile-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
