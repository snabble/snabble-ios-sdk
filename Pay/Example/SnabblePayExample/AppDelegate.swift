//
//  AppDelegate.swift
//  SnabblePayExample
//
//  Created by Andreas Osberghaus on 2023-01-16.
//

import Foundation
import UIKit
import SnabbleLogger

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Logger.shared.logLevel = .debug
        return true
    }
}
