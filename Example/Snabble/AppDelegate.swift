//
//  AppDelegate.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import SnabbleSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Asset.provider = self

        let shopsNavi = UINavigationController(rootViewController: ShopsViewController())
        let accountNavi = UINavigationController(rootViewController: AccountViewController())

        let homeVC = HomeViewController()

        let homeNavi = UINavigationController(rootViewController: homeVC)
        homeNavi.navigationBar.isOpaque = true

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNavi, shopsNavi, accountNavi]
        tabBarController.selectedIndex = 0

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .systemBackground
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        let onboardingViewController = OnboardingViewController()
        onboardingViewController.isModalInPresentation = true
        window?.rootViewController?.present(onboardingViewController, animated: false)

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
