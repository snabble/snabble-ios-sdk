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

public protocol UserValidation: UIViewController {
    func acceptUser(user: SnabbleUser.User) -> Bool
}

public typealias UserInputConformance = UserValidation & UserFieldProviding

public final class UserPaymentViewController: UIViewController {
    private(set) var paymentViewController: UserInputConformance?
    
    public init(paymentViewController: UserInputConformance) {
        self.paymentViewController = paymentViewController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let userVC = UserViewController(user: Snabble.shared.userProvider?.getUser(),
                                        fields: self.paymentViewController?.defaultUserFields ?? UserField.allCases,
                                        requiredFields: self.paymentViewController?.requiredUserFields ?? UserField.allCases)
        userVC.delegate = self
        add(userVC)
        
        self.title = userVC.title
    }

    private func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        child.didMove(toParent: self)
    }
}

extension UserPaymentViewController: UserViewControllerDelegate {
    public func userViewController(_ viewController: UserViewController, didFinishWithUser user: User) {
        guard let paymentViewController else {
            return
        }
        guard paymentViewController.acceptUser(user: user) else {
            return
        }
        self.navigationController?.pushViewController(paymentViewController, animated: true)
    }
}
