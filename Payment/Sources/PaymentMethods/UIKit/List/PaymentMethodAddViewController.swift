//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

import SnabbleCore
import SnabbleAssetProviding
import SnabbleTheme

private extension PaymentMethodAddCell.ViewModel {
    init(entry: PaymentMethodListManager.ProjectEntry) {
        projectId = entry.projectId
        name = entry.name
        count = "\(entry.count)"
    }
}

public final class PaymentMethodAddViewController: UITableViewController {
    private let manager: PaymentMethodListManager
    private var entries: [PaymentMethodListManager.ProjectEntry] = []
    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(_ analyticsDelegate: AnalyticsDelegate?) {
        self.manager = PaymentMethodListManager()
        self.analyticsDelegate = analyticsDelegate

        super.init(style: .insetGrouped)
    }

    init(brandId: Identifier<Brand>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.manager = PaymentMethodListManager(brandId: brandId)
        self.analyticsDelegate = analyticsDelegate

        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = Asset.localizedString(forKey: "Snabble.PaymentMethods.title")
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(PaymentMethodAddCell.self, forCellReuseIdentifier: "cell")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadEntries()
        tableView.reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    private func loadEntries() {
        if let brandId = manager.brandId {
            entries = manager.projectEntries(for: brandId)
        } else {
            entries = manager.allProjectEntries()
        }
    }
}

// MARK: - table view delegate & data source
extension PaymentMethodAddViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodAddCell

        let entry = entries[indexPath.row]
        cell.configure(with: PaymentMethodAddCell.ViewModel(entry: entry))

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let entry = entries[indexPath.row]

        var navigationTarget: UIViewController?

        if let brandId = entry.brandId, manager.brandId == nil {
            // from the starting view, drill-down to the individual projects in this brand
            navigationTarget = PaymentMethodAddViewController(brandId: brandId, self.analyticsDelegate)
        } else {
            // show/add methods for this specific project
            if entry.isEmpty {
                self.addMethod(for: entry.projectId)
            } else {
                navigationTarget = PaymentMethodListViewController(for: entry.projectId, self.analyticsDelegate)
            }
        }

        if let viewController = navigationTarget {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func addMethod(for projectId: Identifier<Project>) {
        guard let project = Snabble.shared.project(for: projectId) else {
            return
        }

        let methods = project.paymentMethods
            .filter { $0.visible }
            .sorted { $0.displayName < $1.displayName }

        let sheet = SelectionSheetController(title: Asset.localizedString(forKey: "Snabble.PaymentMethods.add"), message: nil)

        methods.forEach { method in
            let action = SelectionSheetAction(title: method.displayName, image: method.icon) { [self] _ in
                if method.isAddingAllowed(showAlertOn: self),
                    let controller = method.editViewController(with: projectId, analyticsDelegate) {
                    navigationController?.pushViewController(controller, animated: true)
                }
            }
            sheet.addAction(action)
        }

        sheet.cancelButtonTitle = Asset.localizedString(forKey: "Snabble.cancel")

        self.present(sheet, animated: true)
    }
}
