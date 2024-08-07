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

public final class UserPaymentViewController: UIViewController {
    private(set) weak var paymentViewController: UIViewController?
    
    public init(paymentViewController: UIViewController) {
        self.paymentViewController = paymentViewController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let userVC = UserViewController(user: .init())
        userVC.delegate = self
        add(userVC)
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
            print("no paymentViewController to show for user", user)
            return
        }
        print("UserPaymentViewController User: ", user)
        self.navigationController?.pushViewController(paymentViewController, animated: true)
    }
}
