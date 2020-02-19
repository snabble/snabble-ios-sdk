//
//  MethodSelectionViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class MethodSelectionViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var methods: [MethodProjects]
    private weak var analyticsDelegate: AnalyticsDelegate?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(_ methods: [MethodProjects], _ analyticsDelegate: AnalyticsDelegate?) {
        self.methods = methods
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.PaymentMethods.add".localized()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.tableFooterView = UIView(frame: .zero)

        let nib = UINib(nibName: "MethodSelectionCell", bundle: SnabbleBundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "methodCell")

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil)
            NSLog("ERROR: \(msg)")
        }
    }
}

extension MethodSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.methods.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "methodCell", for: indexPath) as! MethodSelectionCell

        let method = self.methods[indexPath.row]

        let retailers = method.projectNames.joined(separator: ", ")
        let fmt = "Snabble.Payment.usableAt".localized()
        let useableAt = String(format: fmt, retailers)

        cell.setMethod(method.method, useableAt)

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let method = self.methods[indexPath.row]

        if SnabbleUI.implicitNavigation {
            guard let editVC = method.method.editViewController(self.analyticsDelegate) else {
                return
            }

            self.navigationController?.pushViewController(editVC, animated: true)
        } else {
            self.navigationDelegate?.addData(for: method.method)
        }
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }
}
