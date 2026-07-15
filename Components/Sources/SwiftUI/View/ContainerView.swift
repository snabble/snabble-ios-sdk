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
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let container = uiViewController as? ContainerViewController,
              container.viewController !== viewController else { return }

        // Replace the hosted view controller in place (e.g. ApplePayVC → CheckoutStepsVC).
        let old = container.viewController
        old.willMove(toParent: nil)
        old.view.removeFromSuperview()
        old.removeFromParent()

        container.addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(viewController.view)
        viewController.didMove(toParent: container)

        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor)
        ])
    }
    
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
