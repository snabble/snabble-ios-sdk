//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import ColorCompatibility
import SDCAlertView

struct MethodEntry {
    var name: String
    let method: RawPaymentMethod?
    let brandId: Identifier<Brand>?
    let projectId: Identifier<Project>?
    var count: Int

    init(project: Project, count: Int) {
        self.name = project.name
        self.method = nil
        self.brandId = project.brandId
        self.projectId = project.id
        self.count = count
    }

    init(method: RawPaymentMethod, count: Int, for project: Project? = nil) {
        self.name = method.displayName
        self.method = method
        self.brandId = nil
        self.projectId = project?.id
        self.count = count
    }
}

public final class PaymentMethodAddViewController: UIViewController {

    private var entries = [[MethodEntry]]()
    private var brandId: Identifier<Brand>?
    private weak var analyticsDelegate: AnalyticsDelegate?

    private var tableView = UITableView(frame: .zero, style: .grouped)

    public init(_ analyticsDelegate: AnalyticsDelegate?) {
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: nil)
    }

    init(brandId: Identifier<Brand>, _ analyticsDelegate: AnalyticsDelegate?) {
        self.analyticsDelegate = analyticsDelegate
        self.brandId = brandId

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.PaymentMethods.title".localized()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = 44
        tableView.register(PaymentMethodAddCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: tableView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            self.view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: tableView.rightAnchor)
        ])
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let brandId = self.brandId {
            self.entries = getProjectEntries(for: brandId)
        } else {
            self.entries = getAllEntries()
        }

        self.tableView.reloadData()
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
            .filter { $0.editable }
            .sorted { $0.displayName < $1.displayName }
            .map { MethodEntry(method: $0, count: methodCount(for: $0), for: SnabbleAPI.projects[0]) }

        var entries = [[MethodEntry]]()
        entries.append(allEntries)
        return entries
    }

    private func getMultiProjectEntries() -> [[MethodEntry]] {
        // all entries where credit cards are accepted
        var allEntries = SnabbleAPI.projects
            .filter { !$0.shops.isEmpty }
            .filter { $0.paymentMethods.firstIndex { $0.isProjectSpecific } != nil }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        // merge entries belonging to the same brand
        let entriesByBrand = Dictionary(grouping: allEntries, by: { $0.brandId })

        for (brandId, entries) in entriesByBrand {
            guard let brandId = brandId, entries.count > 1, var first = entries.first else {
                continue
            }

            // overwrite the project's name with the brand name
            if let brand = SnabbleAPI.brands?.first(where: { $0.id == brandId }) {
                first.name = brand.name
            }
            first.count = entries.reduce(0) { $0 + self.methodCount(for: $1.projectId) }

            // and replace all matching entries with `first`
            allEntries.removeAll(where: { $0.brandId == brandId })
            allEntries.append(first)
        }

        allEntries.sort { $0.name < $1.name }

        let allMethods = Set(SnabbleAPI.projects.flatMap { $0.paymentMethods }.filter { $0.editable })

        let creditCards = allMethods
            .filter { $0.isProjectSpecific }
            .sorted { $0.displayName < $1.displayName }

        var generalMethods = Array(allMethods.subtracting(creditCards))
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

extension PaymentMethodAddViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return entries.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodAddCell

        cell.entry = entries[indexPath.section][indexPath.row]

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if entries.count == 1 {
            return nil
        }

        switch section {
        case 0: return "Snabble.PaymentMethods.forAllRetailers".localized()
        case 1: return "Snabble.PaymentMethods.forSingleRetailer".localized()
        default: return nil
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let entry = entries[indexPath.section][indexPath.row]

        var navigationTarget: UIViewController?

        if let brandId = entry.brandId, self.brandId == nil {
            // from the starting view, drill-down to the individual projects in this brand
            navigationTarget = PaymentMethodAddViewController(brandId: brandId, self.analyticsDelegate)
        } else if let method = entry.method {
            // show/add retailer-independent methods
            // swiftlint:disable:next empty_count
            if entry.count == 0 {
                navigationTarget = method.editViewController(with: entry.projectId, showFromCart: false, self.analyticsDelegate)
            } else {
                navigationTarget = PaymentMethodListViewControllerNew(method: method, for: entry.projectId, showFromCart: false, self.analyticsDelegate)
            }
        } else if let projectId = entry.projectId {
            // show/add methods for this specific project
            // swiftlint:disable:next empty_count
            if entry.count == 0 {
                self.addMethod(for: projectId)
            } else {
                navigationTarget = PaymentMethodListViewControllerNew(for: projectId, showFromCart: false, self.analyticsDelegate)
            }
        }

        if let viewController = navigationTarget {
            #warning("RN navigation")
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
        methods.forEach { method in
            let title = NSAttributedString(string: method.displayName, attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 17)
            ])
            let action = AlertAction(attributedTitle: title, style: .normal) { [self] _ in
                if let controller = method.editViewController(with: projectId, showFromCart: false, analyticsDelegate) {
                    #warning("RN navigation")
                    navigationController?.pushViewController(controller, animated: true)
                }
            }
            action.imageView.image = method.icon
            sheet.addAction(action)
        }

        let cancelTitle = NSAttributedString(string: "Snabble.Cancel".localized(), attributes: [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.label
        ])
        sheet.addAction(AlertAction(attributedTitle: cancelTitle, style: .preferred, handler: nil))

        self.present(sheet, animated: true)
    }
}

private final class PaymentMethodAddCell: UITableViewCell {
    private var icon: UIImageView
    private var iconWidth: NSLayoutConstraint
    private var nameLabel: UILabel
    private var countLabel: UILabel

    var entry: MethodEntry? {
        didSet {
            icon.image = entry?.method?.icon
            nameLabel.text = entry?.name

            if let projectId = entry?.projectId, entry?.method == nil {
                SnabbleUI.getAsset(.storeIcon, projectId: projectId) { img in
                    self.icon.image = img
                    self.iconWidth.constant = 24
                }
            }
            if let count = entry?.count {
                countLabel.text = "\(count)"
            } else {
                countLabel.text = nil
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        icon = UIImageView()
        iconWidth = NSLayoutConstraint(item: icon, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 38)
        nameLabel = UILabel()
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        countLabel.textColor = ColorCompatibility.systemGray2

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        icon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(icon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)

        self.accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 24),
            iconWidth,

            nameLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            countLabel.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 16),
            countLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        icon.image = nil
        nameLabel.text = nil
        iconWidth.constant = 38
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
