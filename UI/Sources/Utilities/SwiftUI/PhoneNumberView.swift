//
//  PhoneNumberView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 23.08.22.
//

import SwiftUI
import SnabbleAssetProviding
import SnabbleComponents

public struct PhoneNumberView: View {
    let phone: String
    
    @Environment(\.openURL) var openURL
    @Environment(\.projectTrait) private var project

    public var body: some View {
        HStack {
            Image(systemName: "phone")
                .foregroundColor(.gray)
            Button(action: {
                openURL(URL(string: "tel:\(phone)")!)
            }) {
                Text(phone)
                    .foregroundColor(Color.projectPrimary())
            }
        }
    }
}

struct PhoneNumberView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberView(phone: "+49 228 38764911")
    }
}
