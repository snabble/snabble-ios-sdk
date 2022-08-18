//
//  ShopsViewController.swift
//  SnabbleSampleApp
//
//  Created by Uwe Tilemann on 18.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SwiftUI
import SnabbleSDK

extension UIViewController {
    func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView) where Content: View {
        let controller = UIHostingController(rootView: swiftUIView)
        
        addChild(controller)
        view.addSubview(controller.view)

        controller.view.translatesAutoresizingMaskIntoConstraints = false

        let contraints = [
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)
        ]
        NSLayoutConstraint.activate(contraints)
        
        controller.didMove(toParent: self)
    }
}

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let shopFinder = ShopFinderView(model: ProjectModel.shared)
        self.addSubSwiftUIView(shopFinder, to: self.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ProjectModel.shared.startUpdating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ProjectModel.shared.stopUpdating()
    }
}
