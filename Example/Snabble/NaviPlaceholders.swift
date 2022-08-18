//
//  NaviPlaceholders.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class ShopsViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = NSLocalizedString("Shops", comment: "")
        self.tabBarItem.image = UIImage(systemName: "house")
        self.tabBarItem.selectedImage = UIImage(systemName: "house.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AccountViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = NSLocalizedString("Account", comment: "")
        self.tabBarItem.image = UIImage(systemName: "person")
        self.tabBarItem.selectedImage = UIImage(systemName: "person.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
