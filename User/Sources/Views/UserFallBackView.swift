//
//  UserFallBackView.swift
//  
//
//  Created by Andreas Osberghaus on 2024-09-02.
//

import SwiftUI

import SnabbleAssetProviding

public struct UserFallBackView: View {
    public var body: some View {
        Text(Asset.localizedString(forKey: "Snabble.Account.Info.fallback")).header()
    }
}
