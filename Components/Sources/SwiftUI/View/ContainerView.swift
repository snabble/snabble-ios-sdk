//
//  ContainerView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-24.
//

import SwiftUI

public struct ContainerView: UIViewControllerRepresentable {
    public let viewController: UIViewController
        
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
        
    public func makeUIViewController(context: Context) -> UIViewController {
        return ContainerViewController(viewController: viewController)
    }
    
    // swiftlint:disable:next no_empty_block
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class ContainerViewController: UIViewController {
        public let viewController: UIViewController

        init(viewController: UIViewController) {
            self.viewController = viewController
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            addChild(viewController)
            view.addSubview(viewController.view)
            viewController.didMove(toParent: self)
            
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
}
