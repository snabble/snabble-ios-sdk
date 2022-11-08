//
//  ReceiptListContainerViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 08.11.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleCore
import SnabbleUI
import UIKit

final class ReceiptListContainerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Asset.localizedString(forKey: "Snabble.Receipts.title")

        let controller = ReceiptsListViewController(checkoutProcess: nil)
        self.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controller.view)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissReceipts(_:)))

        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        controller.didMove(toParent: self)
    }
    
    @objc
    func dismissReceipts(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
}
