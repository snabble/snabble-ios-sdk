//
//  ContainerView.swift
//  Quartier
//
//  Created by Uwe Tilemann on 28.06.24.
//

import SwiftUI

 struct ContainerView: UIViewControllerRepresentable {
    let viewController: UIViewController
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        return ContainerViewController(viewController: viewController, isPresented: $isPresented)
    }

     // swiftlint:disable:next no_empty_block
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

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

//            addChild(childViewController)
//            view.addSubview(childViewController.view)
//            childViewController.view.frame = view.bounds
//            childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//            childViewController.didMove(toParent: self)
        }
//        override func viewDidDisappear(_ animated: Bool) {
//            super.viewDidDisappear(animated)
//            isPresented = false
//        }
    }
 }
