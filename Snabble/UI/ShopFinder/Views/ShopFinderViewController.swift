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

/// Only use this `ViewController` in a modal presentation
open class ShopFinderViewController: UIViewController {

    @StateObject var viewModel = ShopViewModel.default
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addSubSwiftUIView(ShopFinderView(model: viewModel), to: self.view)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ShopViewModel.default.startUpdating()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ShopViewModel.default.stopUpdating()
    }
}
