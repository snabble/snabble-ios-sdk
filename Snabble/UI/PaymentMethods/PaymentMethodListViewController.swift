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
        default: return nil
        }
    }

    func editViewController(_ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit: return SepaEditViewController(nil, nil, analyticsDelegate)
        case .creditCardMastercard: return CreditCardEditViewController(.mastercard, analyticsDelegate)
        case .creditCardVisa: return CreditCardEditViewController(.visa, analyticsDelegate)
        default: return nil
        }
    }

    var icon: UIImage? {
        switch self {
        case .deDirectDebit: return UIImage.fromBundle("SnabbleSDK/payment-small-sepa")
        case .creditCardVisa: return UIImage.fromBundle("SnabbleSDK/payment-small-visa")
        case .creditCardMastercard: return UIImage.fromBundle("SnabbleSDK/payment-small-mastercard")
        default: return nil
        }
    }

    var order: Int {
        switch self {
        case .deDirectDebit: return 100
        case .creditCardVisa: return 99
        case .creditCardMastercard: return 98
        default: return 0
        }
    }
}

struct MethodProjects {
    let method: RawPaymentMethod
    let projectNames: [String]
}

public final class PaymentMethodListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var addButton: UIBarButtonItem!

    private var paymentDetails = [PaymentMethodDetail]()
    private var initialDetails = 0
    private var methods = [MethodProjects]()
    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(_ analyticsDelegate: AnalyticsDelegate) {
        self.analyticsDelegate = analyticsDelegate
        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.PaymentMethods.title".localized()

        self.methods = self.initializeMethods()
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
            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { action in
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

    // support embedding in as a child viewcontroller
    override public var navigationItem: UINavigationItem {
        return self.parent?.navigationItem ?? super.navigationItem
    }

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

        let selection = MethodSelectionViewController(self.methods, self.analyticsDelegate)
        self.navigationController?.pushViewController(selection, animated: true)
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        self.tableView.isEditing = editing
    }

    private func initializeMethods() -> [MethodProjects] {
        let allPaymentMethods = SnabbleAPI.projects.reduce(into: []) { result, project in
            result.append(contentsOf: project.paymentMethods)
        }
        let paymentMethods = Set(allPaymentMethods.filter({ $0.editable }))

        var methodMap = [RawPaymentMethod: [String]]()
        for pm in paymentMethods {
            for prj in SnabbleAPI.projects {
                if prj.paymentMethods.contains(pm) {
                    methodMap[pm, default: []].append(prj.name)
                }
            }
        }

        if SnabbleAPI.debugMode {
            RawPaymentMethod.allCases.filter{ $0.editable && methodMap[$0] == nil }.forEach {
                methodMap[$0] = ["TEST"]
            }
        }

        return methodMap
            .map { MethodProjects(method: $0, projectNames: $1) }
            .sorted { $0.method.order > $1.method.order }
    }

    // checks if the device passcode and/or biometry is enabled
    private func devicePasscodeSet() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    private func updateTable() {
        self.paymentDetails = PaymentMethodDetails.read()

        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)

        if self.paymentDetails.count > 0 {
            self.navigationItem.rightBarButtonItems = [self.addButton, self.editButtonItem]
        } else {
            self.navigationItem.rightBarButtonItem = self.addButton
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodCell
        let detail = self.paymentDetails[indexPath.row]
        let method = self.methods.first { $0.method == detail.rawMethod }

        if method == nil {
            let projects = SnabbleAPI.projects.filter { $0.paymentMethods.contains(detail.rawMethod) }.map { $0.name }
            cell.setDetail(detail, projects)
        } else {
            cell.setDetail(detail, method?.projectNames)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let details = self.paymentDetails[indexPath.row]

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
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let method = self.paymentDetails[indexPath.row]
        PaymentMethodDetails.remove(at: indexPath.row)
        self.analyticsDelegate?.track(.paymentMethodDeleted(method.rawMethod.displayName))
        NotificationCenter.default.post(name: .paymentMethodsChanged, object: self)
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
