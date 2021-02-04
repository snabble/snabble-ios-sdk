//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

public final class PaymentMethodListViewControllerNew: UIViewController {
    private var tableView = UITableView(frame: .zero, style: .grouped)

    private let details: [[PaymentMethodDetail]]
    private let showFromCart: Bool
    private weak var analyticsDelegate: AnalyticsDelegate?
    private let projectId: Identifier<Project>?

    public init(method: RawPaymentMethod, showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        let details = PaymentMethodDetails.read()
        self.details = [ details.filter { $0.rawMethod == method } ]

        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.projectId = nil

        super.init(nibName: nil, bundle: nil)
    }

    public init(for projectId: Identifier<Project>, showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        let details = PaymentMethodDetails.read().filter { detail in
            switch detail.methodData {
            case .creditcard(let creditcardData):
                return creditcardData.projectId == projectId
            default:
                return false
            }
        }

        var array = [[PaymentMethodDetail]]()
        Dictionary(grouping: details, by: { $0.rawMethod }).values.forEach {
            array.append($0)
        }
        self.details = array

        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate
        self.projectId = projectId

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.PaymentMethods.title".localized()

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMethod))
        self.navigationItem.rightBarButtonItem = addButton

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = 44
        tableView.register(PaymentMethodListCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: tableView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            self.view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: tableView.rightAnchor)
        ])
    }

    @objc private func addMethod() {
        #warning("popup?")
        guard let method = details.first?.first?.rawMethod else {
            return
        }

        if let controller = method.editViewController(with: projectId, showFromCart: showFromCart, analyticsDelegate) {
            #warning("RN navigation")
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension PaymentMethodListViewControllerNew: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return details[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PaymentMethodListCell

        // cell.method = methods[indexPath.row]
        cell.textLabel?.text = details[indexPath.section][indexPath.row].displayName

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let detail = details[indexPath.section][indexPath.row]

        var editVC: UIViewController?
        switch detail.methodData {
        case .sepa:
            editVC = SepaEditViewController(detail, indexPath.row, false, self.analyticsDelegate)
        case .creditcard(let creditcardData):
            editVC = CreditCardEditViewController(creditcardData, indexPath.row, false, self.analyticsDelegate)
        case .paydirektAuthorization:
            editVC = PaydirektEditViewController(detail, indexPath.row, false, self.analyticsDelegate)
        case .tegutEmployeeCard:
            editVC = nil
        }

        if let controller = editVC {
            #warning("RN navigation")
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return details[section].first?.rawMethod.displayName
    }
}

private final class PaymentMethodListCell: UITableViewCell {
    var method: PaymentMethodDetail?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
