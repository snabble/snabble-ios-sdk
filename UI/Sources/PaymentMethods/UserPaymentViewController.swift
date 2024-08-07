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
    var user: SnabbleUser.User? { get set }
    func hasValidUser(user: SnabbleUser.User) -> Bool
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
        
        let userVC = UserViewController(user: .init(),
                                        fields: self.paymentViewController?.defaultUserFields ?? UserField.allCases,
                                        required: self.paymentViewController?.requiredUserFields ?? UserField.allCases)
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

extension UserPaymentViewController: UserViewProxy {
    public func userInfoAvailable(user: SnabbleUser.User) {
        guard let paymentViewController else {
            return
        }
        guard paymentViewController.hasValidUser(user: user) else {
            return
        }
        paymentViewController.user = user
        self.navigationController?.pushViewController(paymentViewController, animated: true)
    }
}
