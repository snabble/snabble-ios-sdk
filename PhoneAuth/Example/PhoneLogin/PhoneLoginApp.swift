//
//  PhoneLoginApp.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 17.01.23.
//

import SwiftUI
import SnabblePhoneAuth

@main
struct PhoneLoginApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneAuthScreen(configuration: .testing)
        }
    }
}
