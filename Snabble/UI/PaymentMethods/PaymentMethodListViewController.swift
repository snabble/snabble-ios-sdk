//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication

extension RawPaymentMethod {
    var displayName: String {
        switch self {
        case .deDirectDebit:
            return "SEPA-Lastschrift"
        case .creditCardMastercard:
            return "Mastercard"
        case .creditCardVisa:
            return "VISA"
        case .creditCardAmericanExpress:
            return "American Express"
        case .gatekeeperTerminal:
            return "Snabble.Payment.payAtSCO".localized()
        case .paydirektOneKlick:
            return "paydirekt"
        case .qrCodePOS, .qrCodeOffline:
            return "Snabble.Payment.payAtCashDesk".localized()
        case .externalBilling:
            return "Snabble.Payment.payViaInvoice".localized()
        case .customerCardPOS:
            return "Snabble.Payment.payUsingCustomerCard".localized()
        }
    }

    func editViewController(with projectId: Identifier<Project>?, showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit:
            return SepaEditViewController(nil, showFromCart, analyticsDelegate)
        case .paydirektOneKlick:
            return PaydirektEditViewController(nil, showFromCart, analyticsDelegate)

        case .creditCardMastercard:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .mastercard, projectId, showFromCart, analyticsDelegate)
            }
        case .creditCardVisa:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .visa, projectId, showFromCart, analyticsDelegate)
            }
        case .creditCardAmericanExpress:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .amex, projectId, showFromCart, analyticsDelegate)
            }

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS, .gatekeeperTerminal:
            ()
        }
        return nil
    }

    var icon: UIImage? {
        switch self {
        case .deDirectDebit: return UIImage.fromBundle("SnabbleSDK/payment/payment-sepa")
        case .creditCardVisa: return UIImage.fromBundle("SnabbleSDK/payment/payment-visa")
        case .creditCardMastercard: return UIImage.fromBundle("SnabbleSDK/payment/payment-mastercard")
        case .creditCardAmericanExpress: return UIImage.fromBundle("SnabbleSDK/payment/payment-amex")
        case .gatekeeperTerminal: return UIImage.fromBundle("SnabbleSDK/payment/payment-sco")
        case .paydirektOneKlick: return UIImage.fromBundle("SnabbleSDK/payment/payment-paydirekt")

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return UIImage.fromBundle("SnabbleSDK/payment/payment-pos")
        }
    }
}

@available(*, deprecated)
public final class PaymentMethodListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private var addButton: UIBarButtonItem!

    private var paymentDetails = [PaymentMethodDetail]()
    private let showUsable: Bool
    private let methods: [MethodProjects]
    private weak var analyticsDelegate: AnalyticsDelegate?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(_ analyticsDelegate: AnalyticsDelegate) {
        self.analyticsDelegate = analyticsDelegate
        self.methods = MethodProjects.initialize()
        self.showUsable = SnabbleAPI.projects.count > 1

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.PaymentMethods.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        let nib = UINib(nibName: "PaymentMethodCell", bundle: SnabbleBundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "cell")

        self.addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(_:)))

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }

        let nc = NotificationCenter.default
        _ = nc.addObserver(forName: .snabblePaymentMethodAdded, object: nil, queue: OperationQueue.main) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTable()
            }
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateTable()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    // support embedding as a child viewcontroller
    override public var navigationItem: UINavigationItem {
        return self.parent?.navigationItem ?? super.navigationItem
    }

    @IBAction private func addButtonTapped(_ sender: Any) {
        self.addPaymentMethod()
    }

    public func addPaymentMethod() {
        self.tableView?.isEditing = false

        if !self.devicePasscodeSet() {
            let mode = BiometricAuthentication.supportedBiometry
            let msg: String
            if mode == .none {
                msg = "Snabble.PaymentMethods.noCodeAlert.noBiometry".localized()
            } else {
                msg = "Snabble.PaymentMethods.noCodeAlert.biometry".localized()
            }

            let alert = UIAlertController(title: "Snabble.PaymentMethods.noDeviceCode".localized(), message: msg, preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }

        if SnabbleUI.implicitNavigation {
            let projectId = SnabbleUI.project.id
            let selection = MethodSelectionViewController(with: projectId, self.methods, showFromCart: false, self.analyticsDelegate)
            self.navigationController?.pushViewController(selection, animated: true)
        } else {
            self.navigationDelegate?.addMethod(fromCart: false)
        }
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        self.tableView.isEditing = editing
    }

    // checks if the device passcode and/or biometry is enabled
    private func devicePasscodeSet() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    private func updateTable() {
        self.paymentDetails = PaymentMethodDetails.read()

        self.tableView.reloadData()

        if SnabbleUI.implicitNavigation {
            if !self.paymentDetails.isEmpty {
                self.navigationItem.rightBarButtonItems = [self.addButton, self.editButtonItem]
            } else {
                self.navigationItem.rightBarButtonItem = self.addButton
            }
        }
        // self.verifySerials()
    }

    // example of cert serial verification
    private func verifySerials() {
        guard
            let cert = SnabbleAPI.certificates.first,
            let encrypter = PaymentDataEncrypter(cert.data),
            let serial = encrypter.getSerial()
        else {
            return
        }

        for detail in self.paymentDetails {
            let ok = detail.serial == serial
            print("serial \(serial) for \(detail.displayName) ok=\(ok)")
            // else: let the server re-encrypt the data
        }
    }
}

extension PaymentMethodListViewController: UITableViewDelegate, UITableViewDataSource {
    private func showEmptyView() {
        let view = InformationButtonView(frame: tableView.bounds)
        let viewModel = InformationButtonView.ViewModel(title: "Snabble.Payment.emptyState.message".localized(),
                                                        buttonTitle: "Snabble.Payment.emptyState.add".localized())
        view.configure(with: viewModel)
        view.button?.addTarget(self, action: #selector(addButtonTapped(_:)), for: .touchUpInside)
        tableView.backgroundView = view
    }

    private func hideEmptyView() {
        tableView.backgroundView = nil
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        paymentDetails.isEmpty ? showEmptyView() : hideEmptyView()
        return paymentDetails.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodCell
        let detail = self.paymentDetails[indexPath.row]
        let method = self.methods.first { $0.method == detail.rawMethod }

        if self.showUsable {
            if method == nil {
                let projects = SnabbleAPI.projects.filter { $0.paymentMethods.contains(detail.rawMethod) }.map { $0.name }
                cell.setDetail(detail, projects)
            } else {
                cell.setDetail(detail, method?.projectNames)
            }
        } else {
            cell.setDetail(detail, nil)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = self.paymentDetails[indexPath.row]

        if SnabbleUI.implicitNavigation {
            var editVC: UIViewController?
            switch detail.methodData {
            case .sepa:
                editVC = SepaEditViewController(detail, false, self.analyticsDelegate)
            case .creditcard:
                editVC = CreditCardEditViewController(detail, false, self.analyticsDelegate)
            case .paydirektAuthorization:
                editVC = PaydirektEditViewController(detail, false, self.analyticsDelegate)
            case .tegutEmployeeCard:
                editVC = nil
            }

            if let editVC = editVC {
                self.navigationController?.pushViewController(editVC, animated: true)
            }
        } else {
            self.navigationDelegate?.editMethod(detail.rawMethod)
        }
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let method = self.paymentDetails[indexPath.row]
        PaymentMethodDetails.remove(method)
        self.analyticsDelegate?.track(.paymentMethodDeleted(method.rawMethod.displayName))
        self.updateTable()
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var methods = self.paymentDetails
        methods.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        self.paymentDetails = methods
        PaymentMethodDetails.save(self.paymentDetails)
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
