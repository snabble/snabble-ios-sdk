//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import ColorCompatibility
import SDCAlertView

public final class PaymentMethodAddViewController: UITableViewController {
    private var entries = [[MethodEntry]]()
    private var brandId: Identifier<Brand>?
    private let showFromCart: Bool
    private weak var analyticsDelegate: AnalyticsDelegate?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.brandId = nil

        super.init(style: SnabbleUI.groupedTableStyle)
    }

    init(brandId: Identifier<Brand>, showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.brandId = brandId
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate

        super.init(style: SnabbleUI.groupedTableStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.PaymentMethods.title".localized()

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = 44
        tableView.register(PaymentMethodAddCell.self, forCellReuseIdentifier: "cell")

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let brandId = self.brandId {
            entries = getProjectEntries(for: brandId)
        } else {
            entries = getAllEntries()
        }

        // special case: remove externalBilling entries where we have no data
        for idx in 0..<entries.count {
            // swiftlint:disable:next empty_count
            entries[idx].removeAll { $0.method == .externalBilling && $0.count == 0 }
        }

        tableView.reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodList)
    }

    private func getProjectEntries(for brandId: Identifier<Brand>) -> [[MethodEntry]] {
        let projectsEntries = SnabbleAPI.projects
            .filter { $0.brandId == brandId }
            .sorted { $0.name < $1.name }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        var entries = [[MethodEntry]]()
        entries.append(projectsEntries)
        return entries
    }

    private func getAllEntries() -> [[MethodEntry]] {
        if SnabbleAPI.projects.count == 1 {
            return getSingleProjectEntries()
        } else {
            return getMultiProjectEntries()
        }
    }

    private func getSingleProjectEntries() -> [[MethodEntry]] {
        let allEntries = SnabbleAPI.projects
            .flatMap { $0.paymentMethods }
            .filter { $0.editable && $0.isAvailable }
            .sorted { $0.displayName < $1.displayName }
            .map { MethodEntry(method: $0, count: methodCount(for: $0), for: SnabbleAPI.projects[0].id) }

        var entries = [[MethodEntry]]()
        entries.append(allEntries)
        return entries
    }

    private func getMultiProjectEntries() -> [[MethodEntry]] {
        // all entries where project-specific methods are accepted
        var allEntries = SnabbleAPI.projects
            .filter { !$0.shops.isEmpty }
            .filter { $0.paymentMethods.firstIndex { $0.isProjectSpecific } != nil }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        // merge entries belonging to the same brand
        let entriesByBrand = Dictionary(grouping: allEntries, by: { $0.brandId })

        for (brandId, entries) in entriesByBrand {
            guard let brandId = brandId, !entries.isEmpty, let first = entries.first else {
                continue
            }

            let brandProjects = SnabbleAPI.projects.filter { $0.brandId == brandId }
            let replacement: MethodEntry
            if brandProjects.count == 1 {
                // only one project in brand, use the project's entry (w/o brand) directly
                replacement = MethodEntry(projectId: first.projectId!, name: first.name, brandId: nil, count: first.count)
            } else {
                // overwrite the project's name with the brand name
                var newEntry = first
                if let brand = SnabbleAPI.brands.first(where: { $0.id == brandId }) {
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

        let editableMethods = SnabbleAPI.projects
            .flatMap { $0.paymentMethods }
            .filter { $0.editable && $0.isAvailable }
        let allMethods = Set(editableMethods)

        let projectSpecificMethods = allMethods.filter { $0.isProjectSpecific }

        var generalMethods = Array(allMethods.subtracting(projectSpecificMethods))
        generalMethods.sort { $0.displayName < $1.displayName }

        var entries = [[MethodEntry]]()
        if !generalMethods.isEmpty {
            entries.append(generalMethods.map { MethodEntry(method: $0, count: methodCount(for: $0)) })
        }

        entries.append(allEntries)

        return entries
    }

    private func methodCount(for projectId: Identifier<Project>?) -> Int {
        guard let projectId = projectId else {
            return 0
        }

        let details = PaymentMethodDetails.read()
        return details.filter { detail in
            switch detail.methodData {
            case .creditcard(let creditcardData):
                return creditcardData.projectId == projectId
            case .datatransAlias(let datatransData):
                return datatransData.projectId == projectId
            case .datatransCardAlias(let datatransCardData):
                return datatransCardData.projectId == projectId
            default:
                return false
            }
        }.count
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

        cell.entry = entries[indexPath.section][indexPath.row]

        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if entries.count == 1 {
            return nil
        }

        switch section {
        case 0: return "Snabble.PaymentMethods.forAllRetailers".localized()
        case 1: return "Snabble.PaymentMethods.forSingleRetailer".localized()
        default: return nil
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let entry = entries[indexPath.section][indexPath.row]

        var navigationTarget: UIViewController?

        if let brandId = entry.brandId, self.brandId == nil {
            // from the starting view, drill-down to the individual projects in this brand
            if SnabbleUI.implicitNavigation {
                navigationTarget = PaymentMethodAddViewController(brandId: brandId, showFromCart: self.showFromCart, self.analyticsDelegate)
            } else {
                navigationDelegate?.showRetailers(for: brandId)
            }
        } else if let method = entry.method {
            // show/add retailer-independent methods
            // swiftlint:disable:next empty_count
            if entry.count == 0 {
                if method.isAddingAllowed(showAlertOn: self) {
                    if SnabbleUI.implicitNavigation {
                        navigationTarget = method.editViewController(with: entry.projectId, showFromCart: false, self.analyticsDelegate)
                    } else {
                        navigationDelegate?.addData(for: method, in: entry.projectId)
                    }
                }
            } else {
                if SnabbleUI.implicitNavigation {
                    navigationTarget = PaymentMethodListViewController(method: method, for: entry.projectId, showFromCart: self.showFromCart, self.analyticsDelegate)
                } else {
                    navigationDelegate?.showData(for: method, in: entry.projectId)
                }
            }
        } else if let projectId = entry.projectId {
            // show/add methods for this specific project
            // swiftlint:disable:next empty_count
            if entry.count == 0 {
                self.addMethod(for: projectId)
            } else {
                if SnabbleUI.implicitNavigation {
                    navigationTarget = PaymentMethodListViewController(for: projectId, showFromCart: self.showFromCart, self.analyticsDelegate)
                } else {
                    navigationDelegate?.showData(for: projectId)
                }
            }
        }

        if let viewController = navigationTarget {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func addMethod(for projectId: Identifier<Project>) {
        guard let project = SnabbleAPI.project(for: projectId) else {
            return
        }

        let methods = project.paymentMethods
            .filter { $0.isProjectSpecific }
            .sorted { $0.displayName < $1.displayName }

        let sheet = AlertController(title: "Snabble.PaymentMethods.choose".localized(), message: nil, preferredStyle: .actionSheet)
        sheet.visualStyle = .snabbleActionSheet

        methods.forEach { method in
            let action = AlertAction(title: method.displayName, style: .normal) { [self] _ in
                if method.isAddingAllowed(showAlertOn: self),
                   let controller = method.editViewController(with: projectId, showFromCart: self.showFromCart, analyticsDelegate) {
                    if SnabbleUI.implicitNavigation {
                        navigationController?.pushViewController(controller, animated: true)
                    } else {
                        navigationDelegate?.addData(for: method, in: projectId)
                    }
                }
            }
            action.imageView.image = method.icon
            sheet.addAction(action)
        }

        sheet.addAction(AlertAction(title: "Snabble.Cancel".localized(), style: .preferred, handler: nil))

        self.present(sheet, animated: true)
    }
}

// stuff that's only used by the RN wrapper
extension PaymentMethodAddViewController: ReactNativeWrapper {
    public func setBrandId(_ brandId: Identifier<Brand>) {
        self.brandId = brandId
    }

    public func setIsFocused(_ focused: Bool) {
        if focused {
            self.viewWillAppear(true)
        }
    }
}
