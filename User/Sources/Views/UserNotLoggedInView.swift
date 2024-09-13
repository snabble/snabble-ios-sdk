//
//  UserNotLoggedInView.swift
//  
//
//  Created by Andreas Osberghaus on 2024-09-02.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

public struct UserNotLoggedInView: View {
    @Binding var showSignin: Bool
    
    public init(showSignin: Binding<Bool>) {
        self._showSignin = showSignin
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text(Asset.localizedString(forKey: "Snabble.Account.notSignedIn")).header()
            PrimaryButtonView(title: Asset.localizedString(forKey: "Snabble.Account.SignIn.title")) {
                showSignin = true
            }
        }
        .padding(.horizontal)
    }
}
