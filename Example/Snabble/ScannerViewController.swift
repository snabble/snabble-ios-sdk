//
//  ScannerViewController.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleUI
import SwiftUI

class AppScannerViewController: UIViewController {
    
    private var buttonContainer = UIStackView()
    private var spinner = UIActivityIndicatorView()

    let shop: Shop
    let shoppingCart: ShoppingCart

    init(shop: Shop) {
        self.shop = shop
        self.shoppingCart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)

        super.init(nibName: nil, bundle: nil)

        self.title = NSLocalizedString("shopping", comment: "")

        self.tabBarItem.image = UIImage(systemName: "basket")
        self.tabBarItem.selectedImage = UIImage(systemName: "basket")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scanButton = UIButton(type: .system)
        scanButton.setTitle(NSLocalizedString("scanner", comment: ""), for: .normal)
        scanButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        scanButton.addTarget(self, action: #selector(scannerButtonTapped(_:)), for: .touchUpInside)
        buttonContainer.addArrangedSubview(scanButton)

        let cartButton = UIButton(type: .system)
        cartButton.setTitle(NSLocalizedString("shoppingCart", comment: ""), for: .normal)
        cartButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        cartButton.addTarget(self, action: #selector(shoppingCartButtonTapped(_:)), for: .touchUpInside)
        buttonContainer.addArrangedSubview(cartButton)

        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.spacing = 16
        buttonContainer.axis = .vertical
        view.addSubview(buttonContainer)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        view.backgroundColor = .systemBackground

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            buttonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])
    }

    @objc private func scannerButtonTapped(_ sender: Any) {
        let detector = BarcodeCamera(detectorArea: .rectangle)
        let scannerViewController = ScannerViewController(shoppingCart, shop, detector)
        scannerViewController.scannerDelegate = self
        scannerViewController.shoppingCartDelegate = self
        scannerViewController.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(scannerViewController, animated: true)
    }

    @objc private func shoppingCartButtonTapped(_ sender: Any) {
        let shoppingCartVC = ShoppingCartViewController(shoppingCart: shoppingCart)
        shoppingCartVC.shoppingCartDelegate = self
        self.navigationController?.pushViewController(shoppingCartVC, animated: true)
    }
}

extension AppScannerViewController: ScannerDelegate {
    func scanMessage(for project: Project, _ shop: Shop, _ product: Product) -> ScanMessage? {
        return nil
    }
}

extension AppScannerViewController: ShoppingCartDelegate {
    func gotoPayment(
        _ method: RawPaymentMethod,
        _ detail: PaymentMethodDetail?,
        _ info: SignedCheckoutInfo,
        _ cart: ShoppingCart,
        _ didStart: @escaping (Bool) -> Void) {
        guard !info.checkoutInfo.paymentMethods.isEmpty else {
            return
        }

        didStart(true)
        let process = PaymentProcess(info, cart, shop: shop)
        process.paymentDelegate = self
        process.start(method, detail) { result in
            Task { @MainActor in
                switch result {
                case .success(let viewController):
                    self.navigationController?.pushViewController(viewController, animated: true)
                case .failure(let error):
                    self.showWarningMessage("Error creating payment process: \(error))")
                }
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
extension AppScannerViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        NSLog("track: \(event)")
    }
}

/// implement these methods to show warning/info messages on-screen, e.g. as toasts
extension AppScannerViewController: MessageDelegate {
    func showInfoMessage(_ message: String) {
        NSLog("warning: \(message)")
    }

    func showWarningMessage(_ message: String) {
        NSLog("info: \(message)")
    }
}

extension AppScannerViewController: PaymentDelegate {
    func checkoutFinished(_ cart: ShoppingCart, _ process: CheckoutProcess?) {
        self.navigationController?.popViewController(animated: true)
    }

    func exitToken(_ exitToken: ExitToken, for shop: Shop) {
        print("exitToken:", exitToken)
    }

    func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        NSLog("payment error: \(method) \(error)")
        return false
    }
}
