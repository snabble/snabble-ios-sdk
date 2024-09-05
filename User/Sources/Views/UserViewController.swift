//
//  UserViewController.swift
//
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI
import Combine

import SnabbleAssetProviding

public final class UserModel: ObservableObject {
    @Published public var user: User
    
    public let fields: [UserField]
    public let required: [UserField]
    
    public init(user: User, fields: [UserField] = UserField.allCases, required: [UserField] = UserField.allCases) {
        self.user = user
        self.fields = fields
        self.required = required
    }
}

public protocol UserViewProxy: AnyObject {
    func userInfoAvailable(user: User)
}

public class UserViewController: UIHostingController<UserView> {
    
    public weak var delegate: UserViewProxy?
    
    public var model: UserModel {
        rootView.model
    }
    
    public init(user: User,
                fields: [UserField] = UserField.allCases,
                required: [UserField] = UserField.allCases
    ) {
        let model = UserModel(user: user, fields: fields, required: required)
        
        let userView = UserView(model: model)
        super.init(rootView: userView)
        self.title = Asset.localizedString(forKey: "Snabble.UserView.title")
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        model.$user
            .sink { updatedUser in
                self.delegate?.userInfoAvailable(user: updatedUser)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
