//
//  UserViewController.swift
//
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI
import Combine

class UserObservable: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
}

public protocol UserViewProxy: AnyObject {
    func userInfoAvailable(user: User)
}

public class UserViewController: UIHostingController<UserView> {
    var userObserver: UserObservable
    
    public weak var delegate: UserViewProxy?
    
    public init(user: User = .init(),
                fields: [UserField] = UserField.allCases,
                required: [UserField] = UserField.allCases
    ) {
        let observer = UserObservable(user: user)
        self.userObserver = observer
        
        let userView = UserView(user: Binding(get: { observer.user }, set: { _ = $0 }),
                                fields: fields,
                                required: required)
        super.init(rootView: userView)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        userObserver.$user
            .sink { updatedUser in
                self.delegate?.userInfoAvailable(user: updatedUser)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
