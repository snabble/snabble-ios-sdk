//
//  TeleCashUserView.swift
//
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI

import SnabbleUser

class UserObservable: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
}

protocol UserViewProxy {
    func userInfoAvailable(user: User)
}

open class TeleCashUserViewController: UIHostingController<TeleCashUserView> {
    var userObserver: UserObservable
    
    public weak var delegate: UserViewProxy?

    init(user: User) {
        self.userObserver = UserObservable(user: user)
        let teleCashUserView = TeleCashUserView(user: $userObserver.user)
        super.init(rootView: teleCashUserView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        userObserver.$user.sink { updatedUser in
            self.delegate?.userInfoAvailable(user: updatedUser)
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

struct TeleCashUserView: View {
    @Binding var user: User
    let userFields = UserField.fieldsWithout([.state, .dateOfBirth])
    
    var body: some View {
        UserView(fields: userFields) { updatedUser in
            print("got User:", updatedUser)
            self.user = updatedUser
        }
    }
}

#Preview {
    TeleCashUserView()
}
