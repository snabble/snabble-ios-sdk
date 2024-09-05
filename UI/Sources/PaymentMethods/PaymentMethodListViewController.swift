//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

public final class PaymentMethodListViewController: UITableViewController {
    private weak var analyticsDelegate: AnalyticsDelegate?

    private(set) var projectId: Identifier<Project>?
    private var data: [PaymentGroup] = [] {
        didSet {
            tableView.backgroundView?.isHidden = !data.isEmpty
        }
    }
    private(set) weak var emptyViewController: PaymentEmptyViewController?

    public init(for projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) {
        self.projectId = projectId
        self.analyticsDelegate = analyticsDelegate
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        emptyViewController?.willMove(toParent: nil)
        emptyViewController?.view.removeFromSuperview()
        emptyViewController?.removeFromParent()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Asset.localizedString(forKey: "Snabble.PaymentMethods.title")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMethod))
        self.navigationItem.rightBarButtonItem = addButton
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(PaymentMethodListCell.self, forCellReuseIdentifier: "cell")
        
        let emptyViewController = PaymentEmptyViewController()
        addChild(emptyViewController)
        tableView.backgroundView = emptyViewController.view
        emptyViewController.didMove(toParent: self)

        tableView.backgroundView?.isHidden = true
        self.emptyViewController = emptyViewController
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let projectId {
            data = Snabble.shared.project(for: projectId)?.availablePayments() ?? []
        } else {
            data = []
        }
        tableView.reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.analyticsDelegate?.track(.viewPaymentMethodList)

        if data.isEmpty && projectId != nil {
            addMethod()
        }
    }

    @objc private func addMethod() {
        addPaymentMethod(for: projectId, analyticsDelegate: analyticsDelegate)
    }
}

extension UIViewController {
    private func showEditController(
        for method: RawPaymentMethod,
        in projectId: Identifier<Project>?,
        analyticsDelegate: AnalyticsDelegate?) {
            
        if method.isAddingAllowed(showAlertOn: self),
            let controller = method.editViewController(with: projectId, analyticsDelegate) {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    /// show the payment selection sheet
    ///
    /// - Parameter for: the project identifier to add a payment method for
    /// - Parameter analyticsDelegate: the optional analytics delegate
    public func addPaymentMethod(
        for projectId: Identifier<Project>?,
        shop: Shop? = nil,
        analyticsDelegate: AnalyticsDelegate?) {

       let methods = Snabble.shared.projects
           .filter { $0.id == projectId }
           .flatMap { $0.paymentMethods }
           .filter { $0.visible }
           .filter { shop == nil || shop?.isAcceptedPaymentMethod($0) == true }

       if methods.count == 1 {
           showEditController(for: methods[0], in: projectId, analyticsDelegate: analyticsDelegate)
       } else {
           let sheet = SelectionSheetController(title: Asset.localizedString(forKey: "Snabble.PaymentMethods.choose"))

           methods.forEach { method in
               let action = SelectionSheetAction(title: method.displayName, image: method.icon) { [self] _ in
                   showEditController(for: method, in: projectId, analyticsDelegate: analyticsDelegate)
               }
               sheet.addAction(action)
           }

           sheet.cancelButtonTitle = Asset.localizedString(forKey: "Snabble.cancel")

           self.present(sheet, animated: true)
       }
    }
}

extension PaymentMethodListViewController {
    fileprivate func payment(at indexPath: IndexPath) -> Payment {
        return data[indexPath.section].items[indexPath.row]
    }
}

// MARK: - table view delegate & data source
extension PaymentMethodListViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        data.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodListCell

        let paymentSelection = payment(at: indexPath)

        let viewModel: PaymentMethodListCellViewModel
        if let detail = paymentSelection.detail {
            viewModel = PaymentMethodListCell.ViewModel(detail: detail)
        } else {
            let method = paymentSelection.method
            
            viewModel = PaymentMethodListCell.ViewModel(displayName: method.displayName, icon: method.icon)
        }
        cell.configure(with: viewModel)

        return cell
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let paymentSelection = payment(at: indexPath)

        var editVC: UIViewController?
        if let detail = paymentSelection.detail {
            switch detail.methodData {
            case .sepa:
                editVC = SepaEditViewController(detail, self.analyticsDelegate)
            case .payoneSepa:
                editVC = SepaDataEditViewController(viewModel: SepaDataModel(detail: detail, projectId: projectId))
            case .teleCashCreditCard:
                editVC = TeleCashCreditCardEditViewController(detail, self.analyticsDelegate)
            case .giropayAuthorization:
                editVC = GiropayEditViewController(detail, for: projectId, with: self.analyticsDelegate)
            case .payoneCreditCard:
                editVC = PayoneCreditCardEditViewController(detail, prefillData: Snabble.shared.userProvider?.getUser(), self.analyticsDelegate)
            case .tegutEmployeeCard:
                editVC = nil
            case .invoiceByLogin:
                if let projectId = projectId, let project = Snabble.shared.project(for: projectId) {
                    let model = InvoiceLoginProcessor(invoiceLoginModel: InvoiceLoginModel(paymentDetail: detail, project: project))

                    editVC = InvoiceViewController(viewModel: model)
                }

            case .datatransAlias, .datatransCardAlias:
                editVC = Snabble.methodRegistry.create(detail: detail, analyticsDelegate: self.analyticsDelegate)
            }
            if let controller = editVC {
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }

    override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return payment(at: indexPath).detail != nil
    }

    override public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let detail = payment(at: indexPath).detail {
            PaymentMethodDetails.remove(detail)
            data[indexPath.section].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
