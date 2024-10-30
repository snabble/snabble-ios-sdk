//
//  UserPaymentViewController.swift
//
//
//  Created by Uwe Tilemann on 07.08.24.
//

import UIKit

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUser
import SwiftUI

public protocol UserValidation: UIViewController {
    func acceptUser(user: SnabbleUser.User) -> Bool
}

public typealias UserInputConformance = UserValidation & UserFieldProviding

public protocol UserPaymentViewControllerDelegate: AnyObject {
    func userPaymentViewController(_ viewController: UserPaymentViewController, didAcceptUser user: SnabbleUser.User)
}

public final class UserPaymentViewController: UIViewController {
    
    private weak var userViewController: UserViewController?
    public weak var delegate: UserPaymentViewControllerDelegate?
    
    public var nextViewController: UserValidation?
    
    let fields: [UserField]
    let requiredFields: [UserField]
    
    public init(
        fields: [UserField] = UserField.allCases,
        requiredFields: [UserField] = UserField.allCases
    ) {
        self.fields = fields
        self.requiredFields = fields
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let userViewController = UserViewController(user: Snabble.shared.userProvider?.getUser(),
                                                    fields: fields,
                                                    requiredFields: requiredFields)
        
        addChild(userViewController)
        view.addSubview(userViewController.view)
        userViewController.view.frame = view.bounds
        userViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        userViewController.didMove(toParent: self)
        self.userViewController = userViewController
        
        self.view = view
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        userViewController?.delegate = self
        title = userViewController?.title
    }
}

extension UserPaymentViewController: UserViewControllerDelegate {
    public func userViewController(_ viewController: UserViewController, didFinishWithUser user: User) {
        if let nextViewController {
            guard nextViewController.acceptUser(user: user) else {
                return
            }
            navigationController?.pushViewController(nextViewController, animated: true)
        } else {
            delegate?.userPaymentViewController(self, didAcceptUser: user)
        }
    }
}
