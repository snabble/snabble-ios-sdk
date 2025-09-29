//
//  DatatransAliasViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Datatrans
import SnabbleCore
import SnabbleUI
import SnabbleAssetProviding

public final class DatatransAliasViewController: UIViewController {
    private weak var containerView: UIStackView?
    private weak var cardNumberLabel: UILabel?
    private weak var cardNumberField: UITextField?
    private weak var expirationDateLabel: UILabel?
    private weak var expirationDateField: UITextField?

    private weak var analyticsDelegate: AnalyticsDelegate?
    private let projectId: Identifier<Project>?
    private let method: RawPaymentMethod?
    private let brand: CreditCardBrand?
    private var transaction: Datatrans.Transaction?
    private let detail: PaymentMethodDetail?

    var user: DatatransUser?

    private var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .natural
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    private var customTextField: UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .label
        textField.borderStyle = .roundedRect
        textField.textAlignment = .natural
        textField.clearButtonMode = .whileEditing
        return textField
    }

    public init(_ method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId
        self.method = method
        self.detail = nil
        self.brand = CreditCardBrand.forMethod(method)

        super.init(nibName: nil, bundle: nil)
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

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground
        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .vertical
        containerView.spacing = 16
        containerView.alignment = .fill
        containerView.distribution = .fill

        let explanationLabel = customLabel
        explanationLabel.numberOfLines = 0
        explanationLabel.font = .preferredFont(forTextStyle: .subheadline)
        explanationLabel.text = Asset.localizedString(forKey: "Snabble.CC.editingHint")

        let cardNumberLabel = customLabel
        cardNumberLabel.font = .preferredFont(forTextStyle: .body)
        cardNumberLabel.text = Asset.localizedString(forKey: "Snabble.CC.cardNumber")

        let cardNumberField = customTextField

        let expirationDateLabel = customLabel
        expirationDateLabel.font = .preferredFont(forTextStyle: .body)
        expirationDateLabel.text = Asset.localizedString(forKey: "Snabble.CC.validUntil")

        let expirationDateField = customTextField

        view.addSubview(containerView)

        containerView.addArrangedSubview(explanationLabel)
        containerView.addArrangedSubview(cardNumberLabel)
        containerView.addArrangedSubview(cardNumberField)
        containerView.addArrangedSubview(expirationDateLabel)
        containerView.addArrangedSubview(expirationDateField)

        containerView.setCustomSpacing(8, after: cardNumberLabel)
        containerView.setCustomSpacing(8, after: expirationDateLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 2),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: containerView.bottomAnchor, multiplier: 2),
            containerView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 2),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: containerView.trailingAnchor, multiplier: 2),

            cardNumberField.heightAnchor.constraint(equalToConstant: 40),
            cardNumberField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cardNumberField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            expirationDateField.heightAnchor.constraint(equalToConstant: 40),
            expirationDateField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            expirationDateField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        self.containerView = containerView
        self.cardNumberLabel = cardNumberLabel
        self.cardNumberField = cardNumberField
        self.expirationDateLabel = expirationDateLabel
        self.expirationDateField = expirationDateField
        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        self.title = method?.displayName
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
            self.containerView?.isHidden = true
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
        self.cardNumberField?.text = displayName
        self.expirationDateField?.text = expirationDate

        self.expirationDateLabel?.isHidden = expirationDate == nil
        self.expirationDateField?.isHidden = expirationDate == nil

        let trash: UIImage? = Asset.image(named: "trash")
        let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = deleteButton
    }

    private func startTransaction(with tokenResponse: TokenResponse, on presentingController: UIViewController) {
        let transaction = Transaction(mobileToken: tokenResponse.mobileToken)
        transaction.delegate = self
        transaction.options.appCallbackScheme = DatatransFactory.appCallbackScheme
        transaction.options.testing = tokenResponse.isTesting ?? false
        transaction.start(presentingController: presentingController)

        self.transaction = transaction
    }

    private func showError(_ msg: String) {
        if let projectId = projectId {
            let project = Snabble.shared.project(for: projectId)
            project?.logError(msg)
        }

        let title: String
        switch method?.datatransMethod {
        case .postFinanceCard: title = Asset.localizedString(forKey: "Snabble.Payment.PostFinanceCard.error")
        case .twint: title = Asset.localizedString(forKey: "Snabble.Payment.Twint.error")
        default: title = Asset.localizedString(forKey: "Snabble.Payment.CreditCard.error")
        }

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
            self.goBack()
        })

        self.present(alert, animated: true)
    }

    private func handleSuccess(_ result: TransactionSuccess) {
        guard
            let projectId = self.projectId,
            let cert = Snabble.shared.certificates.first else {
            return self.showError("no certificate found")
        }

        guard let savedPaymentMethod = result.savedPaymentMethod else {
            return self.showError("transaction success, but no token found")
        }

        if let brand = self.brand {
            if let data = DatatransCreditCardData(gatewayCert: cert.data,
                                                  brand: brand,
                                                  token: DatatransPaymentMethodToken(savedPaymentMethod: savedPaymentMethod),
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
                                        token: DatatransPaymentMethodToken(savedPaymentMethod: savedPaymentMethod),
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

        let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.Payment.Delete.message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(self.method?.rawValue ?? ""))
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    private func goBack() {
        if
            let viewControllers = navigationController?.viewControllers,
            let viewController = viewControllers.first(where: { viewController in
                viewController is UserPaymentViewController
            }),
            let firstIndex = viewControllers.firstIndex(of: viewController),
            firstIndex > viewControllers.startIndex {
            let vcIndex = viewControllers.index(before: firstIndex)
            let viewController = viewControllers[vcIndex]
            navigationController?.popToViewController(viewController, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
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
        let cardOwner: DatatransUser?
    }

    private struct TokenResponse: Decodable {
        let mobileToken: String
        let isTesting: Bool?
    }

    private func fetchToken(_ projectId: Identifier<Project>, _ method: RawPaymentMethod, completion: @escaping @Sendable (TokenResponse?) -> Void) {
        guard
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == method }),
            hasValidOriginType(descriptor),
            let url = descriptor.links?.tokenization?.href
        else {
            return completion(nil)
        }

        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let tokenInput = TokenInput(paymentMethod: method.rawValue, language: language, cardOwner: user)

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
