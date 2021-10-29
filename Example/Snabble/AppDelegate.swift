//
//  AppDelegate.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import Snabble

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let leftNavi = UINavigationController(rootViewController: LeftViewController())
        let rightNavi = UINavigationController(rootViewController: RightViewController())

        let sampleVC = SampleViewController()

        let sampleNavi = UINavigationController(rootViewController: sampleVC)
        sampleNavi.navigationBar.isOpaque = true

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [ leftNavi, sampleNavi, rightNavi ]
        tabBarController.selectedIndex = 1

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.backgroundColor = .systemBackground
        window?.rootViewController = tabBarController

        setupAppearance()

        return true
    }

    private func setupAppearance() {
        let navigationBarAppearanceProxy = UINavigationBar.appearance()
        navigationBarAppearanceProxy.barTintColor = .systemBackground
        navigationBarAppearanceProxy.isTranslucent = false

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navigationBarAppearanceProxy.standardAppearance = navBarAppearance
        navigationBarAppearanceProxy.scrollEdgeAppearance = navBarAppearance

        let tabBarAppearanceProxy = UITabBar.appearance()
        tabBarAppearanceProxy.barTintColor = .systemBackground
        tabBarAppearanceProxy.isTranslucent = false
        tabBarAppearanceProxy.tintColor = .label
        tabBarAppearanceProxy.unselectedItemTintColor = .darkGray

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearanceProxy.standardAppearance = tabBarAppearance
        if #available(iOS 15, *) {
            tabBarAppearanceProxy.scrollEdgeAppearance = tabBarAppearance
        }

        let tabBarItemAppearance = UITabBarItem.appearance()
        tabBarItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.darkGray], for: .normal)
        tabBarItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.label], for: .selected)
    }
}
