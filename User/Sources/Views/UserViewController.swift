//
//  UserViewController.swift
//
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI
import Combine

import SnabbleAssetProviding

public protocol UserViewControllerDelegate: AnyObject {
    func userViewController(_ viewController: UserViewController, didFinishWithUser user: User)
}

public class UserViewController: UIViewController {
    
    public weak var delegate: UserViewControllerDelegate?
    
    private var user: User? {
        didSet {
            if let user {
                delegate?.userViewController(self, didFinishWithUser: user)
            }
        }
    }
    
    private let fields: [UserField]
    private let requiredFields: [UserField]
    
    public init(user: User?,
                fields: [UserField] = UserField.allCases,
                requiredFields: [UserField] = UserField.allCases
    ) {
        self.user = user
        self.fields = fields
        self.requiredFields = requiredFields
        super.init(nibName: nil, bundle: nil)
        self.title = Asset.localizedString(forKey: "Snabble.UserView.title")
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        let userView = UserView(user: userBinding, fields: fields, requiredFields: requiredFields)
        let hostingController = UIHostingController(rootView: userView)
        
        // Add the hosting controller as a child
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        self.view = view
    }
    
    private var userBinding: Binding<User?> {
        Binding<User?>(
            get: { self.user },
            set: { newValue in
                self.user = newValue
            }
        )
    }
}
