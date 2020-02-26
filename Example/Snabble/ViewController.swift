//
//  ViewController.swift
//  Snabble
//
//  Copyright (c) 2019 snabble GmbH. All rights reserved.
//

import UIKit
import Snabble

class ViewController: UIViewController {

    @IBOutlet private weak var buttonContainer: UIStackView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var shoppingCart = ShoppingCart(CartConfig())

    override func viewDidLoad() {
        super.viewDidLoad()
        self.snabbleSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction private func scannerButtonTapped(_ sender: Any) {
        let project = SnabbleAPI.projects[0]
        let shop = project.shops[0]
        let scanner = ScannerViewController(self.shoppingCart, shop, delegate: self)
        scanner.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(scanner, animated: true)
    }

    @IBAction private func shoppingCartButtonTapped(_ sender: Any) {
        self.gotoShoppingCart()
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
            productProvider.setup { _ in
                self.spinner.stopAnimating()
                self.buttonContainer.isHidden = false

                var cartConfig = CartConfig()
                cartConfig.project = project
                cartConfig.shopId = project.shops[0].id
                self.shoppingCart = ShoppingCart(cartConfig)
            }
        }
    }
}

extension ViewController: ScannerDelegate {
    func gotoShoppingCart() {
        let shoppingCart = ShoppingCartViewController(self.shoppingCart, delegate: self)
        self.navigationController?.pushViewController(shoppingCart, animated: true)
    }

    // called when the scanner needs to close itself
    func closeScanningView() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ViewController: ShoppingCartDelegate {
    func gotoPayment(_ info: SignedCheckoutInfo, _ cart: ShoppingCart) {
        let process = PaymentProcess(info, cart, delegate: self)

        process.start { result in
            switch result {
            case .success(let viewController):
                self.navigationController?.pushViewController(viewController, animated: true)
            case .failure(let error):
                self.showWarningMessage("Error creating payment process: \(error))")
            }
        }
    }

    func gotoScanner() {
        self.navigationController?.popViewController(animated: false)
        self.scannerButtonTapped(1)
    }

    func handleCheckoutError(_ error: SnabbleError) -> Bool {
        NSLog("checkout error: \(error)")
        return false
    }
}

/// implement this method to track an event generated from the SDK in your analytics system
extension ViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        NSLog("track: \(event)")
    }
}

/// implement these methods to show warning/info messages on-screen, e.g. as toasts
extension ViewController: MessageDelegate {
    func showInfoMessage(_ message: String) {
        NSLog("warning: \(message)")
    }

    func showWarningMessage(_ message: String) {
        NSLog("info: \(message)")
    }
}

extension ViewController: PaymentDelegate {
    func paymentFinished(_ success: Bool, _ cart: ShoppingCart, _ process: CheckoutProcess?) {
        cart.removeAll()
        self.navigationController?.popViewController(animated: true)
    }

    func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        NSLog("payment error: \(method) \(error)")
        return false
    }
}
