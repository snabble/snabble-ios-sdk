//
//  AppDelegate.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import SnabbleUI
import SnabbleCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var shopsViewController: AppShopsViewController?
    var dashboardViewController: DynamicViewController?
    
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
        Snabble.setup(config: .staging) { [unowned self] snabble in
            // initial config parsed/loaded
            guard let project = snabble.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            // register the project with the UI components
            SnabbleCI.register(project)
            snabble.checkInManager.delegate = self
            snabble.checkInManager.shop = project.shops.first

            // initialize the product database for this project
            snabble.setupProductDatabase(for: project) { [unowned self] _ in
                transitionView(with: project.shops)
            }
        }
    }

    private func transitionView(with shops: [Shop]) {
        let shopsViewController = AppShopsViewController(shops: shops)
        shopsViewController.viewModel.shop = Snabble.shared.checkInManager.shop
        shopsViewController.delegate = self
        self.shopsViewController = shopsViewController
        
        let profileModel: DynamicViewModel = loadJSON("Profile")
        let accountViewController = AccountViewController(viewModel: profileModel)
        let accountNavigationController = UINavigationController(rootViewController: accountViewController)

        let viewModel: DynamicViewModel = loadJSON("Dashboard")
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        self.dashboardViewController = dashboardViewController

        let scannerViewController = AppScannerViewController(shop: shops.first!)
        let scannerNavigationViewController = UINavigationController(rootViewController: scannerViewController)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [dashboardViewController, scannerNavigationViewController, shopsViewController, accountNavigationController]

        window?.rootViewController = tabBarController

        if Onboarding.isRequired || UserDefaults.standard.bool(forKey: "io.snabble.sample.showOnboarding") {
            showOnboarding(on: tabBarController)
        }
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

extension AppDelegate: ShopsViewControllerDelegate {
    func shopsViewController(_ viewController: ShopsViewController, didSelectActionOnShop shop: ShopProviding) {
        print(#function, shop)
    }
}
