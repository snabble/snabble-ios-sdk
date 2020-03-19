//
//  ReceiptsListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import QuickLook

public final class ReceiptPreviewItem: NSObject, QLPreviewItem {
    public let receiptUrl: URL
    public let title: String

    public var previewItemURL: URL? {
        return self.receiptUrl
    }

    public var previewItemTitle: String? {
        return self.title
    }

    public init(_ receiptUrl: URL, _ title: String) {
        self.receiptUrl = receiptUrl
        self.title = title
        super.init()
    }
}

enum OrderEntry {
    case pending(String, String)    // shop name, project id
    case done(Order)
}

public final class ReceiptsListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var quickLook = QLPreviewController()
    private var previewItem: QLPreviewItem!

    private var orderList: OrderList?
    private var orders: [OrderEntry]?
    private var process: CheckoutProcess?
    private var orderId: String?
    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(_ process: CheckoutProcess?, _ analyticsDelegate: AnalyticsDelegate) {
        self.process = process
        self.orderId = process?.orderID
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Receipts.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "ReceiptCell", bundle: SnabbleBundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "receiptCell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.quickLook.dataSource = self
        self.quickLook.delegate = self

        self.emptyLabel.text = "Snabble.Receipts.noReceipts".localized()
        self.emptyLabel.isHidden = true

        self.spinner.startAnimating()

        self.loadOrderList()
        self.startReceiptPolling()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewReceiptList)
    }

    private func loadOrderList() {
        OrderList.load(SnabbleAPI.projects[0]) { result in
            self.orderListLoaded(result)

            if self.tableView.refreshControl == nil {
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
                self.tableView.refreshControl = refreshControl
            }
        }
    }

    private func startReceiptPolling() {
        guard let process = self.process else {
            return
        }

        let poller = PaymentProcessPoller(process, SnabbleUI.project)

        poller.waitFor([.receipt]) { result in
            self.orderId = poller.updatedProcess.orderID
            if let receiptAvailable = result[.receipt], receiptAvailable, self.orderList != nil {
                self.loadOrderList()
            }
        }
    }

    private func orderListLoaded(_ result: Result<OrderList, SnabbleError>) {
        switch result {
        case .success(let orderList):
            self.orderList = orderList
            self.updateDisplay(orderList)

        case .failure:
            // TODO: display error msg
            break
        }
    }

    private func updateDisplay(_ orderList: OrderList) {
        var orders = orderList.orders.map { OrderEntry.done($0) }

        let orderIds: [String] = orders.compactMap {
            if case .done(let entry) = $0 {
                return entry.id
            } else {
                return nil
            }
        }

        if let orderId = self.orderId {
            if !orderIds.contains(orderId) {
                let pending = OrderEntry.pending(SnabbleUI.project.name, SnabbleUI.project.id)
                orders.insert(pending, at: 0)
            }
        }
        self.orders = orders

        self.spinner.stopAnimating()
        if orders.isEmpty {
            self.emptyLabel.isHidden = false
        }
        self.tableView.reloadData()
    }

    @objc private func handleRefresh(_ sender: Any) {
        OrderList.load(SnabbleAPI.projects[0]) { result in
            self.tableView.refreshControl?.endRefreshing()
            self.orderListLoaded(result)
        }
    }
}

extension ReceiptsListViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orders?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell", for: indexPath) as! ReceiptCell

        guard let orders = self.orders else {
            return UITableViewCell(style: .default, reuseIdentifier: "invalidCell")
        }

        let orderEntry = orders[indexPath.row]
        cell.show(orderEntry)

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        guard let orders = self.orders else {
            return
        }

        let orderEntry = orders[indexPath.row]
        guard case .done(let order) = orderEntry else {
            return
        }

        let project = SnabbleAPI.projectFor(order.project) ?? SnabbleAPI.projects[0]

        let cell = self.tableView.cellForRow(at: indexPath)
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        cell?.accessoryType = .none
        cell?.accessoryView = spinner
        self.showOrder(order, project, cell)
    }
}

extension ReceiptsListViewController {
    func showOrder(_ order: Order, _ project: Project, _ cell: UITableViewCell?) {
        order.getReceipt(project) { result in
            cell?.accessoryType = .disclosureIndicator
            cell?.accessoryView = nil
            switch result {
            case .success(let targetPath):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none

                let title = formatter.string(from: order.date)

                self.showQuicklook(targetPath, title)
            case .failure(let error):
                Log.error("error saving receipt: \(error)")
            }
        }
    }

    func showQuicklook(_ url: URL, _ title: String) {
        self.quickLook.currentPreviewItemIndex = 0
        self.previewItem = ReceiptPreviewItem(url, title)
        self.quickLook.reloadData()
        self.navigationController?.pushViewController(self.quickLook, animated: true)

        self.analyticsDelegate?.track(.viewReceiptDetail)
    }

}

extension ReceiptsListViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem
    }
}
