//
//  DatatransAliasViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Datatrans

public final class DatatransAliasViewController: UIViewController {
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var cardNumberLabel: UILabel!
    @IBOutlet private var cardNumber: UITextField!

    @IBOutlet private var expDateLabel: UILabel!
    @IBOutlet private var expirationDate: UITextField!

    @IBOutlet private var explanation: UILabel!

    private weak var analyticsDelegate: AnalyticsDelegate?
    private let showFromCart: Bool
    private let projectId: Identifier<Project>?
    private let method: RawPaymentMethod?
    private var transaction: Datatrans.Transaction?
    private let detail: PaymentMethodDetail?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(_ method: RawPaymentMethod, _ projectId: Identifier<Project>, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        self.method = method
        self.detail = nil

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    init(_ detail: PaymentMethodDetail, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.projectId = nil
        if case .datatransAlias(let data) = detail.methodData {
            self.method = data.method.rawMethod
        } else {
            self.method = nil
        }

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        self.title = method?.displayName

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let detail = detail, case .datatransAlias(let data) = detail.methodData {
            self.cardNumber.text = data.displayName
            let expirationDate = data.expirationDate
            self.expirationDate.text = expirationDate

            self.cardNumberLabel.text = "Snabble.CC.cardNumber".localized()
            self.expDateLabel.text = "Snabble.CC.validUntil".localized()
            self.explanation.text = "Snabble.PaymentCard.editingHint".localized()

            self.expDateLabel.isHidden = expirationDate == nil
            self.expirationDate.isHidden = expirationDate == nil

            let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        } else {
            self.containerView.isHidden = true
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let projectId = self.projectId, let method = self.method {
            fetchToken(projectId, method) { token in
                guard let token = token else {
                    return self.showError("no mobile token")
                }

                print("got mobileToken: \(token)")
                self.startTransaction(token, on: self)
            }
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    private func startTransaction(_ mobileToken: String, on presentingController: UIViewController) {
        let transaction = Transaction(mobileToken: mobileToken)
        transaction.delegate = self
        transaction.options.appCallbackScheme = "snabble"
        transaction.options.testing = true
        transaction.options.useCertificatePinning = true
        transaction.start(presentingController: presentingController)

        self.transaction = transaction
    }

    private func showError(_ msg: String) {
        if let projectId = projectId {
            let project = SnabbleAPI.project(for: projectId)
            project?.logError(msg)
        }

        let titleKey: String
        switch method?.datatransMethod {
        case .postFinanceCard: titleKey = "Snabble.Payment.PostFinanceCard.error"
        case .twint: titleKey = "Snabble.Payment.Twint.error"
        default: return
        }

        let alert = UIAlertController(title: titleKey.localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }

    private func handleSuccess(_ result: TransactionSuccess) {
        guard
            let projectId = self.projectId,
            let cert = SnabbleAPI.certificates.first else {
            return self.showError("no certificate found")
        }

        guard let token = result.paymentMethodToken else {
            return self.showError("transaction success, but no token found")
        }

        guard let method = self.method?.datatransMethod else {
            return self.showError("unknown datatrans method")
        }

        if let data = DatatransData(gatewayCert: cert.data,
                                    method: method,
                                    token: DatatransPaymentMethodToken(token: token),
                                    projectId: projectId) {
            let detail = PaymentMethodDetail(data)
            PaymentMethodDetails.save(detail)
            self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))

            self.goBack()
        }
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Snabble.Payment.delete.message".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.method?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            if self.showFromCart {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if self.showFromCart {
                self.navigationDelegate?.goBackToCart()
            } else {
                self.navigationDelegate?.goBack()
            }
        }
    }
}

// MARK: - datatrans transaction delegate
extension DatatransAliasViewController: TransactionDelegate {
    public func transactionDidFinish(_ transaction: Transaction, result: TransactionSuccess) {
        self.handleSuccess(result)
    }

    public func transactionDidFail(_ transaction: Transaction, error: TransactionError) {
        self.showError("transaction failed: \(error)")
    }

    public func transactionDidCancel(_ transaction: Transaction) {
        self.showError("transaction cancelled")
    }
}

// MARK: - token retrieval

extension DatatransAliasViewController {
    private struct TokenInput: Encodable {
        let paymentMethod: String
        let language: String
    }

    private struct TokenResponse: Decodable {
        let mobileToken: String
    }

    private func fetchToken(_ projectId: Identifier<Project>, _ method: RawPaymentMethod, completion: @escaping (String?) -> Void) {
        guard let project = SnabbleAPI.project(for: projectId), let url = project.links.datatransTokenization?.href else {
            return
        }

        let language = Locale.current.languageCode ?? "en"
        let tokenInput = TokenInput(paymentMethod: method.rawValue, language: language)

        project.request(.post, url, body: tokenInput, timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (result: Result<TokenResponse, SnabbleError>) in
                switch result {
                case .success(let response):
                    completion(response.mobileToken)
                case .failure(let error):
                    print(error)
                    completion(nil)
                }
            }
        }
    }
}
