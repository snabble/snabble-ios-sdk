//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import UIEmptyState
import LocalAuthentication

extension RawPaymentMethod {
    var displayName: String? {
        switch self {
        case .deDirectDebit: return "SEPA-Lastschrift"
        case .creditCardMastercard: return "Mastercard"
        case .creditCardVisa: return "VISA"
        case .creditCardAmericanExpress: return "American Express"
        case .gatekeeperTerminal: return "Snabble.Payment.payAtSCO".localized()

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return nil
        }
    }

    func editViewController(_ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit: return SepaEditViewController(nil, nil, analyticsDelegate)
        case .creditCardMastercard: return CreditCardEditViewController(.mastercard, analyticsDelegate)
        case .creditCardVisa: return CreditCardEditViewController(.visa, analyticsDelegate)
        case .creditCardAmericanExpress: return CreditCardEditViewController(.amex, analyticsDelegate)

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS, .gatekeeperTerminal:
            return nil
        }
    }

    var icon: UIImage? {
        switch self {
        case .deDirectDebit: return UIImage.fromBundle("SnabbleSDK/payment-small-sepa")
        case .creditCardVisa: return UIImage.fromBundle("SnabbleSDK/payment-small-visa")
        case .creditCardMastercard: return UIImage.fromBundle("SnabbleSDK/payment-small-mastercard")
        case .creditCardAmericanExpress: return UIImage.fromBundle("SnabbleSDK/payment-small-amex")
        case .gatekeeperTerminal: return UIImage.fromBundle("SnabbleSDK/payment-cartd-terminal")

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return nil
        }
    }

    var order: Int {
        switch self {
        case .deDirectDebit: return 100
        case .creditCardVisa: return 99
        case .creditCardMastercard: return 98
        case .creditCardAmericanExpress: return 97
        case .gatekeeperTerminal: return 96

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return 0
        }
    }
}

public final class PaymentMethodListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private var addButton: UIBarButtonItem!

    private var paymentDetails = [PaymentMethodDetail]()
    private var initialDetails = 0
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
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        let nib = UINib(nibName: "PaymentMethodCell", bundle: SnabbleBundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "cell")

        self.addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(_:)))

        let paymentDetails = PaymentMethodDetails.read()
        self.initialDetails = paymentDetails.count

        NotificationCenter.default.addObserver(self, selector: #selector(self.methodsChanged(_:)), name: .paymentMethodsChanged, object: nil)

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil)
            NSLog("ERROR: \(msg)")
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateTable()

        let biometry = BiometricAuthentication.supportedBiometry
        if self.initialDetails == 0 && self.initialDetails != self.paymentDetails.count && biometry != .none && !BiometricAuthentication.useBiometry {
            let title = "Snabble.Biometry.Alert.title".localized()
            let msg = "Snabble.Biometry.Alert.message".localized()
            let alert = UIAlertController(title: String(format: title, biometry.name),
                                          message: String(format: msg, biometry.name),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.Biometry.Alert.laterButton".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
                BiometricAuthentication.useBiometry = true
            })

            self.present(alert, animated: true)
            self.initialDetails = self.paymentDetails.count
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    // support embedding as a child viewcontroller
    override public var navigationItem: UINavigationItem {
        return self.parent?.navigationItem ?? super.navigationItem
    }

    // swiftlint:disable:next private_action
    @IBAction public func addButtonTapped(_ sender: Any) {
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
            let selection = MethodSelectionViewController(self.methods, self.analyticsDelegate)
            self.navigationController?.pushViewController(selection, animated: true)
        } else {
            self.navigationDelegate?.addMethod()
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

    @objc private func methodsChanged(_ notification: Notification) {
        self.updateTable()
    }

    private func updateTable() {
        self.paymentDetails = PaymentMethodDetails.read()

        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)

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
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentDetails.count
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
        let details = self.paymentDetails[indexPath.row]

        if SnabbleUI.implicitNavigation {
            var editVC: UIViewController?
            switch details.methodData {
            case .sepa:
                editVC = SepaEditViewController(details, indexPath.row, self.analyticsDelegate)
            case .creditcard(let creditcardData):
                editVC = CreditCardEditViewController(creditcardData, indexPath.row, self.analyticsDelegate)
            case .tegutEmployeeCard:
                editVC = nil
            }

            if let editVC = editVC {
                self.navigationController?.pushViewController(editVC, animated: true)
            }
        } else {
            self.navigationDelegate?.editMethod(details.rawMethod, indexPath.row)
        }
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let method = self.paymentDetails[indexPath.row]
        PaymentMethodDetails.remove(at: indexPath.row)
        self.analyticsDelegate?.track(.paymentMethodDeleted(method.rawMethod.displayName ?? ""))
        NotificationCenter.default.post(name: .paymentMethodsChanged, object: self)
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

extension PaymentMethodListViewController: UIEmptyStateDelegate, UIEmptyStateDataSource {

    public var emptyStateTitle: NSAttributedString {
        return NSAttributedString(string: "Snabble.Payment.emptyState.message".localized(),
                                  attributes: [ .font: UIFont.systemFont(ofSize: 17, weight: .regular) ])
    }

    public var emptyStateButtonTitle: NSAttributedString? {
        return NSAttributedString(string: "Snabble.Payment.emptyState.add".localized(),
                                  attributes: [ .font: UIFont.systemFont(ofSize: 17, weight: .medium) ])
    }

    public var emptyStateButtonSize: CGSize? {
        return CGSize(width: self.view.bounds.width - 32, height: 30)
    }

    public var emptyStateViewCanAnimate: Bool {
        return false
    }

    public func emptyStatebuttonWasTapped(button: UIButton) {
        self.addButtonTapped(button)
    }

}
