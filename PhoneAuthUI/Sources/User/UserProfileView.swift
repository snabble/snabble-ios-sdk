//
//  UserProfileView.swift
//  teo
//
//  Created by Uwe Tilemann on 29.02.24.
//

import SwiftUI

import SnabbleCore
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
        Text(Asset.localizedString(forKey: "Account.Info.fallback")).header()
    }
}

struct UserNotLoggedInView: View {
    @State private var showSignin: Bool = false
    let phoneAuth: PhoneAuth

    public init(phoneAuth: PhoneAuth) {
        self.phoneAuth = phoneAuth
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(Asset.localizedString(forKey: "Settings.notSignedIn")).header()
            PrimaryButtonView(title: Asset.localizedString(forKey: "Account.SignIn.title")) {
                showSignin = true
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showSignin) {
            PhoneAuthScreen(phoneAuth: phoneAuth, kind: .initial)
        }
    }
}
    
public struct UserProfileView: View {
    @Binding public var user: SnabbleNetwork.User?
    
    @ViewProvider(.phoneLoggedIn) var phoneLoggedInView

    @State private var editUser = false
    @State private var changePhoneNumber = false
    let phoneAuth: PhoneAuth
    
    public init(phoneAuth: PhoneAuth, user: Binding<SnabbleNetwork.User?>) {
        self.phoneAuth = phoneAuth
        self._user = user
    }
    
    @ViewBuilder
    var logginView: some View {
        if let user {
            VStack(spacing: 24) {
                if _phoneLoggedInView.isAvailable {
                    phoneLoggedInView
                } else {
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
                        UserScreen(networkManager: phoneAuth.networkManager, user: user, kind: .management)
                    }
                    .sheet(isPresented: $changePhoneNumber) {
                        PhoneAuthScreen(phoneAuth: phoneAuth, kind: .management)
                    }
                }
            }
            .padding([.leading, .trailing])
       } else {
           VStack(spacing: 24) {
               UserFallBackView()
               SecondaryButtonView(title: Asset.localizedString(forKey: "Settings.signOut")) {
                   UserDefaults.standard.setUserSignedIn(false)
               }
           }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if UserDefaults.standard.isUserSignedIn() {
            logginView
        } else {
            UserNotLoggedInView(phoneAuth: phoneAuth)
        }
    }
    
    public var body: some View {
        content
    }
}
