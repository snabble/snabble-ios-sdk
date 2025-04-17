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
    public let user: SnabbleUser.User
    
    @Binding var editUser: Bool
    @Binding var changePhoneNumber: Bool
    
    public init(
        user: SnabbleUser.User,
        editUser: Binding<Bool>,
        changePhoneNumber: Binding<Bool>
    ) {
        self.user = user
        self._editUser = editUser
        self._changePhoneNumber = changePhoneNumber
    }
    
    public var body: some View {
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
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding([.leading, .trailing])
    }
}
