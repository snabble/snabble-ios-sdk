//
//  NaviPlaceholders.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class AccountViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = NSLocalizedString("Sample.account", comment: "")
        self.tabBarItem.image = UIImage(systemName: "person")
        self.tabBarItem.selectedImage = UIImage(systemName: "person.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
