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
        return ContainerViewController(coordinator: context.coordinator)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // swiftlint:disable:next no_empty_block
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    public class Coordinator: NSObject {
        let parent: ContainerView
        
        init(parent: ContainerView) {
            self.parent = parent
        }
        
        var viewController: UIViewController {
            parent.viewController
        }
        
        func close() {
            parent.isPresented = false
        }
    }
    
    class ContainerViewController: UIViewController {
        private let coordinator: Coordinator
        
        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }
        deinit {
            coordinator.close()
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var viewController: UIViewController {
            coordinator.viewController
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
        
//        override func viewDidDisappear(_ animated: Bool) {
//            super.viewDidDisappear(animated)
//            coordinator.close()
//        }
    }
}
