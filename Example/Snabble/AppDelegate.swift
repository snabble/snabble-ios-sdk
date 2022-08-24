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

        snabbleSetup()

        return true
    }

    private func snabbleSetup() {
        let APPID = "snabble-sdk-demo-app-oguh3x"
        let APPSECRET = "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ===="
        let apiConfig = SnabbleSDK.Config(appId: APPID, secret: APPSECRET, environment: .testing)

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
                transitionView(with: project.shops)
            }
        }
    }

    private func transitionView(with shops: [Shop]) {
        let shopsVC = ShopsViewController(shops: shops)
        let accountVC = AccountViewController()
        let homeVC = HomeViewController(shop: shops.first!)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeVC, shopsVC, accountVC]

        window?.rootViewController = tabBarController

        // showOnboarding(on: tabBarController)
    }

    private func showOnboarding(on viewController: UIViewController) {
        let onboardingViewController = OnboardingViewController()
        onboardingViewController.delegate = self
        viewController.present(onboardingViewController, animated: false)
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

extension AppDelegate: OnboardingViewControllerDelegate {
    func onboardingViewControllerDidFinish(_ viewController: OnboardingViewController) {
        viewController.presentingViewController?.dismiss(animated: true)
    }
}
