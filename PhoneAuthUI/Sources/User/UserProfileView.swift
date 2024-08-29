//
//  UserProfileView.swift
//  teo
//
//  Created by Uwe Tilemann on 29.02.24.
//

import SwiftUI

//import SnabbleCore
import SnabbleNetwork
import SnabblePhoneAuth
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
        Text(Asset.localizedString(forKey: "Snabble.Account.Info.fallback")).header()
    }
}

struct UserNotLoggedInView<Teaser: View>: View {
    @State private var showSignin: Bool = false

    let teaser: (() -> Teaser)?
    
    public init(teaser: (() -> Teaser)?) {
        self.teaser = teaser
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(Asset.localizedString(forKey: "Snabble.Account.notSignedIn")).header()
            PrimaryButtonView(title: Asset.localizedString(forKey: "Snabble.Account.SignIn.title")) {
                showSignin = true
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showSignin) {
            print("show sign-up")
            return Color(.red)
            //PhoneAuthScreen(phoneAuth: phoneAuth, kind: .initial, header: teaser)
        }
    }
}

public struct UserProfileView<Teaser: View, Login: View, Fallback: View>: View {
    @Binding public var user: SnabbleUser.User?
    
    private var teaser: (() -> Teaser)?
    private var login: (() -> Login)?
    private var fallback: (() -> Fallback)?
    
    @State private var editUser = false
    @State private var changePhoneNumber = false
    
    public init(user: Binding<SnabbleUser.User?>,
                teaser: (() -> Teaser)?,
                login: (() -> Login)?,
                fallback: (() -> Fallback)?
    ) {
//        self.phoneAuth = phoneAuth
        self._user = user
        
        self.teaser = teaser
        self.login = login
        self.fallback = fallback
    }
    
    @ViewBuilder
    var logginView: some View {
        if let user {
            VStack(spacing: 24) {
                if let login {
                    login()
                } else {
                    Group {
                        if let name = user.fullName {
                            Text(name).header()
                                .frame(maxWidth: .infinity)
                                .truncationMode(.middle)
                                .lineLimit(1)
                        } else {
                            Text(Asset.localizedString(forKey: "Snabble.Account.Info.fallback")).header()
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                        if let address = user.address {
                            ZStack(alignment: .trailing) {
                                VStack {
                                    if let street = address.street {
                                        Text(street)
                                    }
                                    if let zip = address.zip, let city = address.city {
                                        Text(zip + " " + city)
                                    }
                                    if let email = user.email {
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
                    }
                    .sheet(isPresented: $editUser) {
                        Color(.green)
//                        UserScreen(networkManager: phoneAuth.networkManager, user: user, kind: .management)
                    }
                    .sheet(isPresented: $changePhoneNumber) {
                        print("show changePhoneNumber")
                        return Color(.red)
                        //PhoneAuthScreen(phoneAuth: phoneAuth, kind: .management)
                    }
                }
            }
            .padding([.leading, .trailing])
       } else {
           VStack(spacing: 24) {
               if let fallback {
                   fallback()
               } else {
                   UserFallBackView()
               }
           }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if UserDefaults.standard.isUserSignedIn() {
            logginView
        } else {
            UserNotLoggedInView(teaser: teaser)
        }
    }
    
    public var body: some View {
        content
    }
}

extension UserProfileView {
    public init(user: Binding<SnabbleUser.User?>) where Teaser == Never, Login == Never, Fallback == Never {
        self.init(user: user, teaser: nil, login: nil, fallback: nil )
    }
    public init(user: Binding<SnabbleUser.User?>, fallback: (() -> Fallback)?) where Teaser == Never, Login == Never {
        self.init(user: user, teaser: nil, login: nil, fallback: fallback)
    }
}
