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

    var shopsViewController: ShopsViewController?

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
        let apiConfig = SnabbleSDK.Config(appId: APPID, secret: APPSECRET, environment: .staging)

        Snabble.setup(config: apiConfig) { [unowned self] snabble in
            // initial config parsed/loaded
            guard let project = snabble.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            // register the project with the UI components
            SnabbleUI.register(project)
            snabble.checkInManager.delegate = self
            snabble.checkInManager.shop = project.shops.first

            // initialize the product database for this project
            let productProvider = snabble.productProvider(for: project)
            productProvider.setup { [unowned self] _ in
                transitionView(with: project.shops)
            }
        }
    }

    private func transitionView(with shops: [Shop]) {
        let shopsViewController = ShopsViewController(shops: shops)
        shopsViewController.viewModel.shop = Snabble.shared.checkInManager.shop
        self.shopsViewController = shopsViewController
        
        let accountViewController = AccountViewController()
        let homeViewController = HomeViewController(shop: shops.first!)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeViewController, shopsViewController, accountViewController]

        window?.rootViewController = tabBarController

        showOnboarding(on: tabBarController)
    }

    private func showOnboarding(on viewController: UIViewController) {
        let viewModel: OnboardingViewModel = loadJSON("Onboarding")
        let onboardingViewController = OnboardingViewController(viewModel: viewModel)
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
        tabBarAppearanceProxy.tintColor = .accent()
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
        tabBarItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.accent()], for: .selected)
    }
}

extension AppDelegate: OnboardingViewControllerDelegate {
    func onboardingViewControllerDidFinish(_ viewController: OnboardingViewController) {
        viewController.presentingViewController?.dismiss(animated: true)
    }
}

import CoreLocation

extension AppDelegate: CheckInManagerDelegate {
    func checkInManager(_ checkInManager: CheckInManager, locationAuthorizationNotGranted authorizationStatus: CLAuthorizationStatus) {}

    func checkInManager(_ checkInManager: CheckInManager, locationAccuracyNotSufficient accuracyAuthorization: CLAccuracyAuthorization) {}

    func checkInManager(_ checkInManager: CheckInManager, didFailWithError error: Error) {}

    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop) {
        shopsViewController?.viewModel.shop = shop
    }

    func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop) {
        shopsViewController?.viewModel.shop = nil
    }
}
