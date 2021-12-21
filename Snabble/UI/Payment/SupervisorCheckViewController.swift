//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

class BaseCheckViewController: UIViewController {
    private let checkoutProcess: CheckoutProcess
    private let shop: Shop
    private let shoppingCart: ShoppingCart

    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?

    private let spinner = UIActivityIndicatorView()
    private let label = UILabel()

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess

        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        if #available(iOS 13, *) {
            spinner.style = .medium
        }
        view.addSubview(spinner)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = checkoutProcess.paymentInformation?.qrCodeContent ?? checkoutProcess.id

        view.addSubview(label)

        NSLayoutConstraint.activate([
            spinner.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 16),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 32),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.startTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - polling timer
    private func startTimer() {
        self.processTimer?.invalidate()
        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let project = SnabbleUI.project
            self.checkoutProcess.update(project,
                                taskCreated: { self.sessionTask = $0 },
                                completion: { self.update($0) })
        }
    }

    private func stopTimer() {
        self.processTimer?.invalidate()

        self.sessionTask?.cancel()
        self.sessionTask = nil
        self.spinner.stopAnimating()
    }

    // MARK: - process updates
    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        var continuePolling = true
        switch result.result {
        case .success(let process):
            print("routingTarget", process.routingTarget)
            print("checks", process.checks)
            print("payment", process.paymentState)
            if process.hasFailedChecks {
                let reject = SupervisorRejectedViewController(process)
                self.navigationController?.pushViewController(reject, animated: true)
            }
            if process.allChecksSuccessful {
                continuePolling = false
                switch process.rawPaymentMethod {
                case .applePay: () // TODO
                case .gatekeeperTerminal:
                    continuePolling = process.paymentState == .pending
                default: ()
                }
            }
        case .failure(let error):
            Log.error(String(describing: error))
        }
        asdasd
        if continuePolling {
            self.startTimer()
        } else {
            self.stopTimer()
            let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: shoppingCart, checkoutProcess: process)
            self.navigationController?.pushViewController(checkoutSteps, animated: true)
        }
    }
}

final class SupervisorCheckViewController: BaseCheckViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Supervisor Check"
    }
}

final class GatekeeperCheckViewController: BaseCheckViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Gatekeeper Check"
    }
}
