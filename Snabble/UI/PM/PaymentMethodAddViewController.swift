//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import ColorCompatibility

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

    init(method: RawPaymentMethod, count: Int) {
        self.name = method.displayName
        self.method = method
        self.brandId = nil
        self.projectId = nil
        self.count = count
    }
}

public class PaymentMethodAddViewController: UIViewController {

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
            self.entries = getProjectTargets(for: brandId)
        } else {
            self.entries = getAllTargets()
        }

        self.tableView.reloadData()
    }

    private func getProjectTargets(for brandId: Identifier<Brand>) -> [[MethodEntry]] {
        let projectTargets = SnabbleAPI.projects
            .filter { $0.brandId == brandId }
            .sorted { $0.name < $1.name }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        var targets = [[MethodEntry]]()
        targets.append(projectTargets)
        return targets
    }

    private func getAllTargets() -> [[MethodEntry]] {
        if SnabbleAPI.projects.count == 1 {
            return getSingleProjectTargets()
        } else {
            return getMultiProjectTargets()
        }
    }

    private func getSingleProjectTargets() -> [[MethodEntry]] {
        let allTargets = SnabbleAPI.projects
            .flatMap { $0.paymentMethods }
            .filter { $0.editable }
            .sorted { $0.displayName < $1.displayName }
            .map { MethodEntry(method: $0, count: methodCount(for: $0)) }

        var targets = [[MethodEntry]]()
        targets.append(allTargets)
        return targets
    }

    private func getMultiProjectTargets() -> [[MethodEntry]] {
        // all targets where credit cards are accepted
        var allTargets = SnabbleAPI.projects
            .filter { !$0.shops.isEmpty }
            .filter {
                $0.paymentMethods.contains(.creditCardAmericanExpress)
                    || $0.paymentMethods.contains(.creditCardMastercard)
                    || $0.paymentMethods.contains(.creditCardVisa)
            }
            .map { MethodEntry(project: $0, count: self.methodCount(for: $0.id)) }

        // merge targets belonging to the same brand
        let targetsByBrand = Dictionary(grouping: allTargets, by: { $0.brandId })

        for (brandId, targets) in targetsByBrand {
            guard let brandId = brandId, targets.count > 1, var first = targets.first else {
                continue
            }

            // overwrite the project's name with the brand name
            if let brand = SnabbleAPI.brands?.first(where: { $0.id == brandId }) {
                first.name = brand.name
            }
            first.count = targets.reduce(0) { $0 + self.methodCount(for: $1.projectId) }

            // and replace all matching targets with `first`
            allTargets.removeAll(where: { $0.brandId == brandId })
            allTargets.append(first)
        }

        allTargets.sort { $0.name < $1.name }

        let allMethods = Set(SnabbleAPI.projects.flatMap { $0.paymentMethods }.filter { $0.editable })

        var creditCards: [RawPaymentMethod] = allMethods.filter {
            $0 == .creditCardVisa || $0 == .creditCardMastercard || $0 == .creditCardAmericanExpress
        }
        creditCards.sort { $0.displayName < $1.displayName }

        var generalMethods = Array(allMethods.subtracting(creditCards))
        generalMethods.sort { $0.displayName < $1.displayName }

        var targets = [[MethodEntry]]()
        if !generalMethods.isEmpty {
            targets.append(generalMethods.map { MethodEntry(method: $0, count: methodCount(for: $0)) })
        }

        targets.append(allTargets)

        return targets
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

        let target = entries[indexPath.section][indexPath.row]
        cell.entry = target

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if entries.count == 1 {
            return nil
        }

        switch section {
        case 0: return "Händlerübergreifend"
        case 1: return "Für einzelnen Händler"
        default: return nil
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let target = entries[indexPath.section][indexPath.row]

        var navigationTarget: UIViewController?

        if let projectId = target.projectId, self.brandId != nil {
            let methods = MethodProjects.initialize()
            navigationTarget = MethodSelectionViewController(with: projectId, methods, showFromCart: false, self.analyticsDelegate)
        } else if let method = target.method {
            navigationTarget = method.editViewController(with: target.projectId, showFromCart: false, self.analyticsDelegate)
        } else if let brandId = target.brandId {
            navigationTarget = PaymentMethodAddViewController(brandId: brandId, self.analyticsDelegate)
        }

        if let viewController = navigationTarget {
            #warning("RN navigation")
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

private class PaymentMethodAddCell: UITableViewCell {
    private var icon: UIImageView
    private var iconWidth: NSLayoutConstraint
    private var nameLabel: UILabel
    private var countLabel: UILabel

    var entry: MethodEntry? {
        didSet {
            icon.image = entry?.method?.icon
            nameLabel.text = entry?.name

            if let projectId = entry?.projectId {
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
