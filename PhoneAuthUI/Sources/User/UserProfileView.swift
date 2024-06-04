//
//  UserProfileView.swift
//  teo
//
//  Created by Uwe Tilemann on 29.02.24.
//

import SwiftUI
import SnabbleNetwork
import SnabbleAssetProviding
import SnabbleUser

private extension SnabbleNetwork.User {
    var fullName: String? {
        guard let details else {
            return nil
        }
        let fullName = "\(details.firstName ?? "") \(details.lastName ?? "")"
        
        return fullName.count > 1 ? fullName : nil
    }
}

struct UserFallBackView: View {
    var body: some View {
        Text(Asset.localizedString(forKey: "Account.Info.fallback")).header()
    }
}

struct UserNotLoggedInView: View {
    @State private var showSignin: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text(Asset.localizedString(forKey: "Settings.notSignedIn")).header()
            PrimaryButtonView(title: Asset.localizedString(forKey: "Account.SignIn.title")) {
                showSignin = true
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showSignin, content: {
            PhoneAuthScreen(configuration: phoneAuthConfguration, kind: .initial)
        })
    }
}
    
public struct UserProfileView: View {
    // TODO: this must be fixed, @AppStorage not working here
//    @AppStorage(UserDefaults.userKey) var user
    @State private var user: SnabbleNetwork.User?

    @State private var editUser = false
    @State private var changePhoneNumber = false
    
    public init() {
    }
    
    @ViewBuilder
    var logginView: some View {
        if let user {
            VStack(spacing: 16) {
                if let name = user.fullName {
                    Text(name).header()
                        .frame(maxWidth: .infinity)
                        .truncationMode(.middle)
                        .lineLimit(1)
                } else {
                    Text(Asset.localizedString(forKey: "Account.Info.fallback")).header()
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                if let details = user.details {
                    ZStack(alignment: .trailing) {
                        VStack {
                            if let street = details.street {
                                Text(street)
                            }
                            if let zip = details.zip, let city = details.city {
                                Text(zip + " " + city)
                            }
                            if let email = details.email {
                                Text(email)
                            }
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding([.leading, .trailing])
                        .truncationMode(.middle)

                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editUser.toggle()
                    }
                }
                if let phoneNumber = user.phoneNumber {
                    ZStack(alignment: .trailing) {
                        Text(phoneNumber)
                            .frame(maxWidth: .infinity)
                            .padding([.leading, .trailing])
                        
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        changePhoneNumber.toggle()
                    }
                }
    
                SecondaryButtonView(title: Asset.localizedString(forKey: "Settings.signOut")) {
                    UserDefaults.standard.setUserSignedIn(false)
                }
                .sheet(isPresented: $editUser) {
                    UserScreen(user: user, kind: .management)
                }
                .sheet(isPresented: $changePhoneNumber) {
                    PhoneAuthScreen(configuration: phoneAuthConfguration, kind: .management)
                }
            }
            .padding([.leading, .trailing])
       } else {
            UserFallBackView()
        }
    }
    
    @ViewBuilder
    var content: some View {
        if UserDefaults.standard.isUserSignedIn() {
            logginView
        } else {
            UserNotLoggedInView()
        }
    }
    
    public var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // TODO: .shadow(color: Color.shadow, radius: 6, x: 0, y: 6)
            .shadow(radius: 6, x: 0, y: 6)
            .padding()
    }
}

public class UserProfileViewController: UIHostingController<UserProfileView> {

    public init() {
        super.init(rootView: UserProfileView())
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.invalidateIntrinsicContentSize()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.zPosition = 1
    }
}
