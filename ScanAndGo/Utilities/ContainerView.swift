//
//  ContainerView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 28.06.24.
//

import SwiftUI

public struct ContainerView: UIViewControllerRepresentable {
    public let viewController: UIViewController
    @Binding public var isPresented: Bool
    
    public init(viewController: UIViewController, isPresented: Binding<Bool>) {
        self.viewController = viewController
        self._isPresented = isPresented
    }
    public func makeUIViewController(context: Context) -> UIViewController {
        return ContainerViewController(viewController: viewController, isPresented: $isPresented)
    }
    
    // swiftlint:disable:next no_empty_block
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class ContainerViewController: UIViewController {
        let childViewController: UIViewController
        @Binding var isPresented: Bool
        
        init(viewController: UIViewController, isPresented: Binding<Bool>) {
            self.childViewController = viewController
            self._isPresented = isPresented
            
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            addChild(childViewController)
            view.addSubview(childViewController.view)
            childViewController.didMove(toParent: self)
            
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            print("container view did appear")
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            print("container view did disappear")
            isPresented = false
        }
    }
}
