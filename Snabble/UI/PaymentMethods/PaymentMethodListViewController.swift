//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SDCAlertView

public final class PaymentMethodListViewController: UITableViewController {
    private weak var analyticsDelegate: AnalyticsDelegate?
    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    private(set) var projectId: Identifier<Project>?
    private var details = [[PaymentMethodDetail]]()

    public init(for projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) {
        self.projectId = projectId
        self.analyticsDelegate = analyticsDelegate
        super.init(style: SnabbleUI.groupedTableStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = L10n.Snabble.PaymentMethods.title

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMethod))
        self.navigationItem.rightBarButtonItem = addButton

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = 44
        tableView.register(PaymentMethodListCell.self, forCellReuseIdentifier: "cell")

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.details = []

        if let projectId = self.projectId {
            let details = PaymentMethodDetails.read().filter { detail in
                switch detail.methodData {
                case .creditcard(let creditcardData):
                    return creditcardData.projectId == projectId
                case .datatransCardAlias(let cardAlias):
                    return cardAlias.projectId == projectId
                case .datatransAlias(let alias):
                    return alias.projectId == projectId
                case .tegutEmployeeCard, .sepa, .paydirektAuthorization:
                    return SnabbleAPI.project(for: projectId)?.paymentMethods.contains(where: { $0 == detail.rawMethod}) ?? false
                }
            }

            Dictionary(grouping: details, by: { $0.rawMethod })
                .values
                .sorted { $0[0].displayName < $1[0].displayName }
                .forEach {
                    self.details.append($0)
                }
        }

        self.tableView.reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    @objc private func addMethod() {
        let methods = SnabbleAPI.projects
            .filter { $0.id == projectId }
            .flatMap { $0.paymentMethods }
            .filter { $0.editable }

        if methods.count == 1 {
            showEditController(for: methods[0])
        } else {
            let sheet = AlertController(title: L10n.Snabble.PaymentMethods.choose, message: nil, preferredStyle: .actionSheet)
            sheet.visualStyle = .snabbleActionSheet

            methods.forEach { method in
                let action = AlertAction(title: method.displayName, style: .normal) { [self] _ in
                    showEditController(for: method)
                }
                action.imageView.image = method.icon
                sheet.addAction(action)
            }

            sheet.addAction(AlertAction(title: L10n.Snabble.cancel, style: .preferred, handler: nil))

            self.present(sheet, animated: true)
        }
    }

    private func showEditController(for method: RawPaymentMethod) {
        if method.isAddingAllowed(showAlertOn: self),
           let controller = method.editViewController(with: projectId, analyticsDelegate) {
            if SnabbleUI.implicitNavigation {
                navigationController?.pushViewController(controller, animated: true)
            } else {
                navigationDelegate?.addData(for: method, in: self.projectId)
            }
        }
    }
}

// MARK: - table view delegate & data source
extension PaymentMethodListViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return details[section].count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodListCell

        let viewModel = PaymentMethodListCell.ViewModel(detail: details[indexPath.section][indexPath.row])
        cell.configure(with: viewModel)

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let detail = details[indexPath.section][indexPath.row]

        var editVC: UIViewController?
        switch detail.methodData {
        case .sepa:
            editVC = SepaEditViewController(detail, self.analyticsDelegate)
        case .creditcard:
            editVC = CreditCardEditViewController(detail, self.analyticsDelegate)
        case .paydirektAuthorization:
            editVC = PaydirektEditViewController(detail, self.analyticsDelegate)
        case .tegutEmployeeCard:
            editVC = nil
        case .datatransAlias, .datatransCardAlias:
            editVC = SnabbleAPI.methodRegistry.create(detail: detail, analyticsDelegate: self.analyticsDelegate)
        }

        if let controller = editVC {
            if SnabbleUI.implicitNavigation {
                self.navigationController?.pushViewController(controller, animated: true)
            } else {
                navigationDelegate?.editMethod(detail)
            }
        }
    }

    override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        let detail = details[indexPath.section][indexPath.row]
        PaymentMethodDetails.remove(detail)
        details[indexPath.section].remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return details[section].first?.rawMethod.displayName
    }
}

// stuff that's only used by the RN wrapper
extension PaymentMethodListViewController: ReactNativeWrapper {
    public func setProjectId(_ projectId: Identifier<Project>) {
        self.projectId = projectId
    }

    public func setIsFocused(_ focused: Bool) {
        if focused {
            self.viewWillAppear(true)
        }
    }
}
