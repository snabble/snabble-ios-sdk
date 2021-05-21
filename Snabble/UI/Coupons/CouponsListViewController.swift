//
//  CouponsListViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

public final class CouponsListViewController: UITableViewController {

    private var coupons = [[CouponEntry]]()
    private var sections = [String]()

    public init() {
        super.init(style: SnabbleUI.groupedTableStyle)

        self.setupCoupons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)

        let scanButton = UIBarButtonItem(image: UIImage.fromBundle("SnabbleSDK/icon-barcode"), style: .plain, target: self, action: #selector(scanTapped(_:)))

        let plusButton = UIBarButtonItem(image: UIImage.fromBundle("SnabbleSDK/icon-plus"), style: .plain, target: self, action: #selector(addTapped(_:)))

        parent?.navigationItem.rightBarButtonItems = [scanButton, plusButton]
    }

    private func setupCoupons() {
        let couponEntries = CouponManager.shared.coupons
        let dict = Dictionary(grouping: couponEntries, by: { $0.coupon.projectID })

        var idNames = [(Identifier<Project>, String)]()
        for id in dict.keys {
            guard let project = SnabbleAPI.project(for: id) else {
                continue
            }
            idNames.append((id, project.name))
        }

        sections.removeAll()
        coupons.removeAll()
        for (id, name) in idNames.sorted(by: { $0.1 < $1.1 }) {
            sections.append(name)
            coupons.append(dict[id]!)
        }
    }

    @objc private func scanTapped(_ sender: Any) {
        let scanner = CouponScanViewController()
        navigationController?.pushViewController(scanner, animated: true)
    }

    @objc private func addTapped(_ sender: Any) {
        let coupons = SnabbleAPI.projects.filter { !$0.printedCoupons.isEmpty }.flatMap { $0.printedCoupons }
        CouponManager.shared.addAll(coupons)
        setupCoupons()
        tableView.reloadData()
    }
}

// MARK: - table view
extension CouponsListViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coupons[section].count
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            return cell
        }()

        let coupon = coupons[indexPath.section][indexPath.row]
        cell.textLabel?.text = coupon.coupon.name
        cell.detailTextLabel?.text = coupon.coupon.id

        cell.accessoryType = coupon.active ? .checkmark : .none

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        coupons[indexPath.section][indexPath.row].active.toggle()
        let coupon = coupons[indexPath.section][indexPath.row]

        CouponManager.shared.activate(coupon.coupon, active: coupon.active)

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        let coupon = coupons[indexPath.section][indexPath.row]
        CouponManager.shared.remove(coupon.coupon)
        setupCoupons()
        tableView.reloadData()
    }
}
