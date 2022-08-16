//
//  SampleViewController.swift
//  Snabble Sample App
//
//  Copyright (c) 2021 snabble GmbH. All rights reserved.
//

import UIKit
import SnabbleSDK
import SwiftUI

class SampleViewController: UIViewController {
    
    private var buttonContainer = UIStackView()
    private var spinner = UIActivityIndicatorView()

    private var shoppingCart: ShoppingCart?

    private var shop: Shop?

    private var onboardingDone = false
    
    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = "Snabble"

        self.tabBarItem.image = UIImage(named: "scan-off")
        self.tabBarItem.selectedImage = UIImage(named: "scan-on")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scanButton = UIButton(type: .system)
        scanButton.setTitle(NSLocalizedString("Scanner", comment: ""), for: .normal)
        scanButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        scanButton.addTarget(self, action: #selector(scannerButtonTapped(_:)), for: .touchUpInside)
        buttonContainer.addArrangedSubview(scanButton)

        let cartButton = UIButton(type: .system)
        cartButton.setTitle(NSLocalizedString("Shopping Cart", comment: ""), for: .normal)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.showOnboardingView()
        self.snabbleSetup()
    }

    func showOnboardingView() {
        guard onboardingDone == false else {
            return
        }
        let controller = UIHostingController(rootView: OnboardingView(model: OnboardingModel.shared))

        controller.isModalInPresentation = true
        self.present(controller, animated: false) {
            self.onboardingDone = true
        }
    }

    func snabbleSetup() {
        let APPID = "snabble-sdk-demo-app-oguh3x"
        let APPSECRET = "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ===="
        let apiConfig = SnabbleSDK.Config(appId: APPID, secret: APPSECRET)

        Asset.provider = self
        
        Snabble.setup(config: apiConfig) { snabble in
            // initial config parsed/loaded
            guard let project = snabble.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            // register the project with the UI components
            SnabbleUI.register(project)
            self.shop = project.shops.first!

            // initialize the product database for this project
            let productProvider = snabble.productProvider(for: project)
            productProvider.setup { _ in
                self.spinner.stopAnimating()
                self.buttonContainer.isHidden = false

                let cartConfig = CartConfig(shop: self.shop!)
                self.shoppingCart = ShoppingCart(with: cartConfig)
            }
        }
    }

    @objc private func scannerButtonTapped(_ sender: Any) {
        guard let shoppingCart = self.shoppingCart, let shop = Snabble.shared.projects.first?.shops.first else {
            return
        }

        let detector = BuiltinBarcodeDetector(detectorArea: .rectangle)
        let scannerViewController = ScannerViewController(shoppingCart, shop, detector)
        scannerViewController.scannerDelegate = self
//        scannerViewController.shoppingCartDelegate = self
        scannerViewController.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(scannerViewController, animated: true)
    }

    @objc private func shoppingCartButtonTapped(_ sender: Any) {
        guard let shoppingCart = self.shoppingCart else {
            return
        }

        let shoppingCartVC = ShoppingCartViewController(shoppingCart)
        shoppingCartVC.shoppingCartDelegate = self
        self.navigationController?.pushViewController(shoppingCartVC, animated: true)
    }

}

extension SampleViewController: AssetProviding {
    func color(named name: String, domain: Any?) -> UIColor? {
        return nil
    }
    
    func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight?, domain: Any?) -> UIFont? {
        return UIFont.preferredFont(forTextStyle: style)
    }
    
    func image(named name: String, domain: Any?) -> UIImage? {
        
        return UIImage(named: name)
    }
    
    func localizedString(forKey: String, domain: Any?) -> String? {
        return nil
    }
    
    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL? {
        return nil
    }
    func appearance(for domain: Any?) -> CustomAppearance? {
        return nil
    }
}

extension SampleViewController: ScannerDelegate {
    func scanMessage(for project: Project, _ shop: Shop, _ product: Product) -> ScanMessage? {
        return nil
    }
}

extension SampleViewController: ShoppingCartDelegate {
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
        let process = PaymentProcess(info, cart, shop: self.shop!)
        process.paymentDelegate = self
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
extension SampleViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        NSLog("track: \(event)")
    }
}

/// implement these methods to show warning/info messages on-screen, e.g. as toasts
extension SampleViewController: MessageDelegate {
    func showInfoMessage(_ message: String) {
        NSLog("warning: \(message)")
    }

    func showWarningMessage(_ message: String) {
        NSLog("info: \(message)")
    }
}

extension SampleViewController: PaymentDelegate {
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
