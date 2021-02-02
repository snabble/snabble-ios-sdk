//
//  PaymentMethodAddViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

struct MethodEntry {
    var name: String
    let brandId: Identifier<Brand>?
    let projectId: Identifier<Project>?

    init(_ project: Project) {
        self.name = project.name
        self.brandId = project.brandId
        self.projectId = project.id
    }

    init(name: String) {
        self.name = name
        self.brandId = nil
        self.projectId = nil
    }
}

public class PaymentMethodAddViewController: UIViewController {

    private var targets = [[MethodEntry]]()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    init(brand: Identifier<Brand>) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.initializeTargets()

        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: tableView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            self.view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: tableView.rightAnchor)
        ])
    }

    private func initializeTargets() {
        // all targets where credit cards are accepted
        var allTargets = SnabbleAPI.projects
            .filter { !$0.shops.isEmpty }
            .filter {
                $0.paymentMethods.contains(.creditCardAmericanExpress)
                    || $0.paymentMethods.contains(.creditCardMastercard)
                    || $0.paymentMethods.contains(.creditCardVisa)
            }
            .map { MethodEntry($0) }

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

        self.targets.removeAll()
        if !generalMethods.isEmpty {
            self.targets.append(generalMethods.map { MethodEntry(name: $0.displayName) })
        }

        self.targets.append(allTargets)
    }
}

extension PaymentMethodAddViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return targets.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return targets[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let target = targets[indexPath.section][indexPath.row]

        cell.textLabel?.text = target.name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if targets.count == 1 {
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

        let target = targets[indexPath.section][indexPath.row]
        print("selected \(target)")
    }
}
