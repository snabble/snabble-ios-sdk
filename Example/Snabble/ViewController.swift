//
//  ViewController.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import Snabble

class ViewController: UIViewController {

    @IBOutlet private weak var buttonContainer: UIStackView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var shoppingCart: ShoppingCart?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.snabbleSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func snabbleSetup() {
        let APPID = "your-app-id-here"
        let APPSECRET = "your-app-secret-here"
        let apiConfig = SnabbleAPIConfig(appId: APPID, baseUrl: "https://api.snabble-testing.io", secret: APPSECRET)

        SnabbleAPI.setup(apiConfig) {
            // initial config parsed/loaded
            guard let project = SnabbleAPI.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            // register the project with the UI components
            SnabbleUI.register(project)

            // initialize the product database for this project
            let productProvider = SnabbleAPI.productProvider(for: project)
            productProvider.setup { _ in
                self.spinner.stopAnimating()
                self.buttonContainer.isHidden = false

                let cartConfig = CartConfig(projectId: project.id, shopId: project.shops[0].id)
                self.shoppingCart = ShoppingCart(cartConfig)
            }
        }
    }

    @IBAction private func scannerButtonTapped(_ sender: Any) {
        guard let shoppingCart = self.shoppingCart, let shop = SnabbleAPI.projects.first?.shops.first else {
            return
        }
        
        let detector = BuiltinBarcodeDetector(detectorArea: .rectangle, messageDelegate: nil)
        let scanner = ScannerViewController(shoppingCart, shop, detector, scannerDelegate: self, cartDelegate: nil, shoppingListDelegate: nil)
        scanner.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(scanner, animated: true)
    }

    @IBAction private func shoppingCartButtonTapped(_ sender: Any) {
        guard let shoppingCart = self.shoppingCart else {
            return
        }

        let shoppingCartVC = ShoppingCartViewController(shoppingCart, cartDelegate: self)
        self.navigationController?.pushViewController(shoppingCartVC, animated: true)
    }

}

extension ViewController: ScannerDelegate {
    func scanMessage(for project: Project, _ shop: Shop, _ product: Product) -> ScanMessage? {
        return nil
    }

    func gotoBarcodeEntry() {
        // nop, we're using the shiny new integrated scanner/cart
    }

    // called when the scanner needs to close itself
    func closeScanningView() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ViewController: ShoppingCartDelegate {
    func gotoPayment(_ method: RawPaymentMethod, _ detail: PaymentMethodDetail?, _ info: SignedCheckoutInfo, _ cart: ShoppingCart) {
        guard !info.checkoutInfo.paymentMethods.isEmpty else {
            return
        }

        let process = PaymentProcess(info, cart, delegate: self)
        process.start(method, detail) { result in
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
    func paymentFinished(_ success: Bool, _ cart: ShoppingCart, _ process: CheckoutProcess?, _ rawJson: [String: Any]?) {
        if success {
            cart.removeAll(endSession: true, keepBackup: false)
        }
        self.navigationController?.popViewController(animated: true)
    }

    func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        NSLog("payment error: \(method) \(error)")
        return false
    }
}
