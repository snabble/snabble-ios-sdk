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

        setupAppearance()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .systemBackground
        window?.rootViewController = LoadingViewController()
        window?.makeKeyAndVisible()

        // Show onboarding
//        window?.rootViewController?.present(OnboardingViewController(), animated: false)

        snabbleSetup()

        return true
    }

    private func snabbleSetup() {
        let APPID = "snabble-sdk-demo-app-oguh3x"
        let APPSECRET = "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ===="
        let apiConfig = SnabbleSDK.Config(appId: APPID, secret: APPSECRET)

        Snabble.setup(config: apiConfig) { snabble in
            // initial config parsed/loaded
            guard let project = snabble.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            // register the project with the UI components
            SnabbleUI.register(project)
            snabble.checkInManager.shop = project.shops.first

            // initialize the product database for this project
            let productProvider = snabble.productProvider(for: project)
            productProvider.setup { [unowned self] _ in
                transitionView(with: project.shops.first!)
            }
        }
    }

    private func transitionView(with shop: Shop) {
        let shopsNavi = UINavigationController(rootViewController: ShopsViewController())
        let accountNavi = UINavigationController(rootViewController: AccountViewController())
        let homeNavi = UINavigationController(rootViewController: HomeViewController(shop: shop))

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNavi, shopsNavi, accountNavi]

        window?.rootViewController = tabBarController
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
