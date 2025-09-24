//
//  SnabblePayExampleApp.swift
//  SnabblePayExample
//
//  Created by Andreas Osberghaus on 2022-12-08.
//

import SwiftUI
import SnabblePay

@main
struct SnabblePayExampleApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var viewModel = AccountsViewModel()
    
    var body: some Scene {
        WindowGroup {
            AccountsView()
                .environment(viewModel)
        }
    }
}
