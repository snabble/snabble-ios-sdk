//
//  ViewController.swift
//  Snabble
//
//  Copyright (c) 2018 snabble GmbH. All rights reserved.
//

import UIKit
import Snabble

class ViewController: UIViewController {

    @IBOutlet weak var buttonContainer: UIStackView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    private var shoppingCart = ShoppingCart(CartConfig())

    override func viewDidLoad() {
        super.viewDidLoad()
        self.snabbleSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func scannerButtonTapped(_ sender: Any) {
        let project = SnabbleAPI.projects[0]
        let shop = project.shops[0]
        let scanner = ScannerViewController(project, self.shoppingCart, shop, delegate: self)
        scanner.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(scanner, animated: true)
    }

    @IBAction func shoppingCartButtonTapped(_ sender: Any) {
        let shoppingCart = ShoppingCartViewController(self.shoppingCart, delegate: self)
        self.navigationController?.pushViewController(shoppingCart, animated: true)
    }

    func snabbleSetup() {
        let APPID = "your-app-id-here"
        let APPSECRET = "your-app-secret-here"
        let apiConfig = SnabbleAPIConfig(appId: APPID, baseUrl: "https://api.snabble-testing.io", secret: APPSECRET)

        SnabbleAPI.setup(apiConfig) {
            // initial config parsed/loaded
            let project = SnabbleAPI.projects[0]

            // register the project with the UI components
            SnabbleUI.register(project)

            // initialize the product database for this project
            let productProvider = SnabbleAPI.productProvider(for: project)
            productProvider.setup() { _ in
                self.spinner.stopAnimating()
                self.buttonContainer.isHidden = false

                var cartConfig = CartConfig()
                cartConfig.project = project
                cartConfig.shop = project.shops[0]
                self.shoppingCart = ShoppingCart(cartConfig)
            }
        }
    }
}

extension ViewController: ScannerDelegate {
    func closeScanningView() {
        //
    }
}

extension ViewController: ShoppingCartDelegate {
    func gotoPayment(_ info: SignedCheckoutInfo, _ cart: ShoppingCart) {
        //
    }

    func gotoScanner() {
        //
    }

    func handleCheckoutError(_ error: ApiError?) -> Bool {
        return false
    }
}

extension ViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        //
    }
}

extension ViewController: MessageDelegate {
    func showInfoMessage(_ message: String) {
        //
    }

    func showWarningMessage(_ message: String) {
        //
    }
}

