//
//  NaviPlaceholders.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class LeftViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = "Account"



        
        self.tabBarItem.image = UIImage(systemName: "person")
        self.tabBarItem.selectedImage = UIImage(systemName: "person.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RightViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = "Settings"
        self.tabBarItem.image = UIImage(systemName: "gearshape")
        self.tabBarItem.selectedImage = UIImage(systemName: "gearshape.fill")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
