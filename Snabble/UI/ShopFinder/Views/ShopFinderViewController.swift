//
//  ShopFinderViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import Foundation
import UIKit
import SwiftUI

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

/// A UIViewController wrapping SwiftUI's ShopFinderView
open class ShopFinderViewController: UIViewController {
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addSubSwiftUIView(ShopFinderView(), to: self.view)
    }
}
