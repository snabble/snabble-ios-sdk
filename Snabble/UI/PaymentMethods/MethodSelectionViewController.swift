//
//  MethodSelectionViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class MethodSelectionViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var methods: [MethodProjects]
    private weak var analyticsDelegate: AnalyticsDelegate?

    init(_ methods: [MethodProjects], _ analyticsDelegate: AnalyticsDelegate?) {
        self.methods = methods
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.PaymentMethods.add".localized()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.tableFooterView = UIView(frame: .zero)

        let nib = UINib(nibName: "MethodSelectionCell", bundle: SnabbleBundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "methodCell")
    }
}

extension MethodSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.methods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "methodCell", for: indexPath) as! MethodSelectionCell

        let method = self.methods[indexPath.row]

        cell.icon.image = method.method.icon
        cell.nameLabel.text = method.method.displayName

        let retailers =  method.projectNames.joined(separator: ", ")
        let fmt = "Snabble.Payment.usableAt".localized()
        cell.useLabel.text = String(format: fmt, retailers)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let method = self.methods[indexPath.row]
        guard let vc = method.method.editViewController(self.analyticsDelegate) else {
            return
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }
}
