//
//  UserProfileView.swift
//  teo
//
//  Created by Uwe Tilemann on 29.02.24.
//

import SwiftUI

import SnabbleNetwork
import SnabbleAssetProviding

public struct UserProfileView: View {
//    @Binding public var user: SnabbleUser.User?
    
    public let user: SnabbleUser.User
    
//    private var teaser: (() -> Teaser)?
//    private var login: (() -> Login)?
//    private var fallback: (() -> Fallback)?
    
//    public var onEditUser: () -> Void
//    public var onChangePhoneNumber: () -> Void
    
    @Binding var editUser: Bool
    @Binding var changePhoneNumber: Bool
    
    public init(user: SnabbleUser.User,
                editUser: Binding<Bool>,
                changePhoneNumber: Binding<Bool>
//                teaser: (() -> Teaser)?,
//                login: (() -> Login)?,
//                fallback: (() -> Fallback)?
    ) {
        self.user = user
        self._editUser = editUser
        self._changePhoneNumber = changePhoneNumber
        
//        self.teaser = teaser
//        self.login = login
//        self.fallback = fallback
    }
    
    @ViewBuilder
    var logginView: some View {
        VStack(spacing: 24) {
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
                            
        }
        .frame(maxWidth: .infinity, minHeight: 190)
        .padding([.leading, .trailing])
        
//        .sheet(isPresented: $editUser) {
//            Color(.green)
//                        UserScreen(networkManager: phoneAuth.networkManager, user: user, kind: .management)
//        }
//        .sheet(isPresented: $changePhoneNumber) {
//            Color(.red)
//                    PhoneAuthScreen(phoneAuth: phoneAuth, kind: .management)
//        }
        
    //       } else {
    //           VStack(spacing: 24) {
    //               if let fallback {
    //                   fallback()
    //               } else {
    //                   UserFallBackView()
    //               }
    //           }
    //        }
    }
    
//    @ViewBuilder
//    var content: some View {
//        if UserDefaults.standard.isUserSignedIn() {
//            logginView
//        } else {
//            UserNotLoggedInView(teaser: teaser)
//        }
//    }
    
    public var body: some View {
        logginView
    }
}

//extension UserProfileView {
//    public init(user: Binding<SnabbleUser.User?>) where Teaser == Never, Login == Never, Fallback == Never {
//        self.init(user: user, teaser: nil, login: nil, fallback: nil )
//    }
//    public init(user: Binding<SnabbleUser.User?>, fallback: (() -> Fallback)?) where Teaser == Never, Login == Never {
//        self.init(user: user, teaser: nil, login: nil, fallback: fallback)
//    }
//}
