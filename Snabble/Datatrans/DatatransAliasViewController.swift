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
    private let projectId: Identifier<Project>?
    private let method: RawPaymentMethod?
    private let brand: CreditCardBrand?
    private var transaction: Datatrans.Transaction?
    private let detail: PaymentMethodDetail?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(_ method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        self.method = method
        self.detail = nil
        self.brand = CreditCardBrand.forMethod(method)

        super.init(nibName: nil, bundle: SnabbleDTBundle.main)
    }

    init(_ detail: PaymentMethodDetail, _ analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate
        self.projectId = nil
        if case .datatransAlias(let data) = detail.methodData {
            self.method = data.method.rawMethod
            self.brand = nil
        } else if case .datatransCardAlias(let data) = detail.methodData {
            self.brand = data.brand
            self.method = data.brand.method
        } else {
            self.method = nil
            self.brand = nil
        }

        super.init(nibName: nil, bundle: SnabbleDTBundle.main)
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

        if let detail = detail {
            if case .datatransAlias(let data) = detail.methodData {
                setupView(data.displayName, data.expirationDate)
            } else if case .datatransCardAlias(let data) = detail.methodData {
                setupView(data.displayName, data.expirationDate)
            }
        } else {
            self.containerView.isHidden = true
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let projectId = self.projectId, let method = self.method {
            fetchToken(projectId, method) { [weak self] response in
                guard let self = self, let tokenResponse = response else {
                    self?.showError("no mobile token")
                    return
                }

                print("got mobileToken: \(tokenResponse.mobileToken)")
                self.startTransaction(with: tokenResponse, on: self)
            }
        }

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.transaction?.delegate = nil
        self.transaction = nil
    }

    private func setupView(_ displayName: String, _ expirationDate: String?) {
        self.cardNumber.text = displayName
        self.expirationDate.text = expirationDate

        self.cardNumberLabel.text = L10n.Snabble.Cc.cardNumber
        self.expDateLabel.text = L10n.Snabble.Cc.validUntil
        self.explanation.text = L10n.Snabble.PaymentCard.editingHint

        self.expDateLabel.isHidden = expirationDate == nil
        self.expirationDate.isHidden = expirationDate == nil

        let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
        let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = deleteButton
    }

    private func startTransaction(with tokenResponse: TokenResponse, on presentingController: UIViewController) {
        let transaction = Transaction(mobileToken: tokenResponse.mobileToken)
        transaction.delegate = self
        transaction.options.appCallbackScheme = DatatransFactory.appCallbackScheme
        transaction.options.testing = tokenResponse.isTesting ?? false
        transaction.options.useCertificatePinning = true
        transaction.start(presentingController: presentingController)

        self.transaction = transaction
    }

    private func showError(_ msg: String) {
        if let projectId = projectId {
            let project = SnabbleAPI.project(for: projectId)
            project?.logError(msg)
        }

        let title: String
        switch method?.datatransMethod {
        case .postFinanceCard: title = L10n.Snabble.Payment.PostFinanceCard.error
        case .twint: title = L10n.Snabble.Payment.Twint.error
        default: title = L10n.Snabble.Payment.CreditCard.error
        }

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
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

        if let brand = self.brand {
            if let data = DatatransCreditCardData(gatewayCert: cert.data,
                                                  brand: brand,
                                                  token: DatatransPaymentMethodToken(token: token),
                                                  projectId: projectId) {
                saveDetail(PaymentMethodDetail(data))
            } else {
                showError("can't create details for cc brand \(brand.rawValue)")
            }
            return
        }

        if let method = self.method?.datatransMethod {
            if let data = DatatransData(gatewayCert: cert.data,
                                        method: method,
                                        token: DatatransPaymentMethodToken(token: token),
                                        projectId: projectId) {
                saveDetail(PaymentMethodDetail(data))
            } else {
                showError("can't create details for method \(method.rawValue)")
            }
            return
        }

        self.showError("unknown datatrans method or cc brand")
    }

    private func saveDetail(_ detail: PaymentMethodDetail) {
        PaymentMethodDetails.save(detail)
        self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))

        self.goBack()
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: L10n.Snabble.Payment.Delete.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.yes, style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.method?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: L10n.Snabble.no, style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.navigationDelegate?.goBack()
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
        let isTesting: Bool?
    }

    private func fetchToken(_ projectId: Identifier<Project>, _ method: RawPaymentMethod, completion: @escaping (TokenResponse?) -> Void) {
        guard
            let project = SnabbleAPI.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == method }),
            hasValidOriginType(descriptor),
            let url = descriptor.links?.tokenization?.href
        else {
            return completion(nil)
        }

        let language = Locale.current.languageCode ?? "en"
        let tokenInput = TokenInput(paymentMethod: method.rawValue, language: language)

        project.request(.post, url, body: tokenInput, timeout: 2) { request in
            guard let request = request else {
                return completion(nil)
            }

            project.perform(request) { (result: Result<TokenResponse, SnabbleError>) in
                switch result {
                case .success(let response):
                    completion(response)
                case .failure(let error):
                    print(error)
                    completion(nil)
                }
            }
        }
    }

    private func hasValidOriginType(_ descriptor: PaymentMethodDescriptor) -> Bool {
        return descriptor.acceptedOriginTypes?.contains(.datatransAlias) == true ||
            descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true
    }
}
