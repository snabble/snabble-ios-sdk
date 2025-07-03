//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

private struct MethodEntry {
    var name: String
    let brandId: Identifier<Brand>?
    let projectId: Identifier<Project>
    var count: Int

    init(project: Project, count: Int) {
        self.init(projectId: project.id, name: project.name, brandId: project.brandId, count: count)
    }

    init(projectId: Identifier<Project>, name: String, brandId: Identifier<Brand>?, count: Int) {
        self.projectId = projectId
        self.name = name
        self.brandId = brandId
        self.count = count
    }
}

private extension PaymentMethodAddCell.ViewModel {
    init(methodEntry: MethodEntry) {
        projectId = methodEntry.projectId
        name = methodEntry.name
        count = "\(methodEntry.count)"
    }
}

public final class PaymentMethodAddViewController: UITableViewController {
    private var entries = [[MethodEntry]]()
    private var brandId: Identifier<Brand>?
    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(_ analyticsDelegate: AnalyticsDelegate?) {
        self.analyticsDelegate = analyticsDelegate
        self.brandId = nil

        super.init(style: .insetGrouped)
    }

    init(brandId: Identifier<Brand>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brandId = brandId
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

        if let brandId = self.brandId {
            entries = projectEntries(for: brandId)
        } else {
            entries = multiProjectEntries()
        }

        tableView.reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    private func projectEntries(for brandId: Identifier<Brand>) -> [[MethodEntry]] {
        let projectsEntries = Snabble.shared.projects
            .filter { $0.brandId == brandId }
            .filter { $0.paymentMethods.firstIndex { $0.dataRequired } != nil }
            .sorted { $0.name < $1.name }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        var entries = [[MethodEntry]]()
        entries.append(projectsEntries)
        return entries
    }

    private func multiProjectEntries() -> [[MethodEntry]] {
        var entries = [[MethodEntry]]()

        var allEntries = Snabble.shared.projects
            .filter { !$0.shops.isEmpty }
            .filter { $0.paymentMethods.firstIndex { $0.dataRequired } != nil }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        // merge entries belonging to the same brand
        let entriesByBrand = Dictionary(grouping: allEntries, by: { $0.brandId })

        for (brandId, entries) in entriesByBrand {
            guard let brandId = brandId, !entries.isEmpty, let first = entries.first else {
                continue
            }

            let brandProjects = Snabble.shared.projects.filter { $0.brandId == brandId }
            let replacement: MethodEntry
            if brandProjects.count == 1 {
                // only one project in brand, use the project's entry (w/o brand) directly
                replacement = MethodEntry(projectId: first.projectId, name: first.name, brandId: nil, count: first.count)
            } else {
                // overwrite the project's name with the brand name
                var newEntry = first
                if let brand = Snabble.shared.brands.first(where: { $0.id == brandId }) {
                    newEntry.name = brand.name
                }
                newEntry.count = entries.reduce(0) { $0 + self.methodCount(for: $1.projectId) }
                replacement = newEntry
            }

            // and replace all matching entries with `first`
            allEntries.removeAll(where: { $0.brandId == brandId })
            allEntries.append(replacement)
        }

        allEntries.sort { $0.name < $1.name }

        entries.append(allEntries)
        return entries
    }

    private func methodCount(for projectId: Identifier<Project>) -> Int {
        let details = PaymentMethodDetails.read()
        let count = details.filter { detail in
            switch detail.methodData {
            case .teleCashCreditCard(let telecashData):
                return telecashData.projectId == projectId
            case .datatransAlias(let datatransData):
                return datatransData.projectId == projectId
            case .datatransCardAlias(let datatransCardData):
                return datatransCardData.projectId == projectId
            case .payoneCreditCard(let payoneData):
                return payoneData.projectId == projectId
            case .payoneSepa(let payoneSepaData):
                return payoneSepaData.projectId == projectId
            case .sepa, .tegutEmployeeCard, .giropayAuthorization, .invoiceByLogin:
                return Snabble.shared.project(for: projectId)?.paymentMethods.contains(detail.rawMethod) ?? false
            }
        }.count

        return ApplePay.canMakePayments(with: projectId) ? count + 1 : count
    }

    private func methodCount(for method: RawPaymentMethod) -> Int {
        let details = PaymentMethodDetails.read()
        return details.filter { $0.rawMethod == method }.count
    }
}

// MARK: - table view delegate & data source
extension PaymentMethodAddViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return entries.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries[section].count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodAddCell

        let methodEntry = entries[indexPath.section][indexPath.row]
        cell.configure(with: PaymentMethodAddCell.ViewModel(methodEntry: methodEntry))

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let entry = entries[indexPath.section][indexPath.row]

        var navigationTarget: UIViewController?

        if let brandId = entry.brandId, self.brandId == nil {
            // from the starting view, drill-down to the individual projects in this brand
            navigationTarget = PaymentMethodAddViewController(brandId: brandId, self.analyticsDelegate)
        } else {
            // show/add methods for this specific project
            // swiftlint:disable:next empty_count
            if entry.count == 0 {
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

        let sheet = SelectionSheetController(title: Asset.localizedString(forKey: "Snabble.PaymentMethods.choose"), message: nil)

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
