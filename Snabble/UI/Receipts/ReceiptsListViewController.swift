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
    case pending(String, Identifier<Project>)    // shop name, project id
    case done(Order)
}

public final class ReceiptsListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var quickLookDataSources: [QuicklookPreviewControllerDataSource] = []

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

        let poller = PaymentProcessPoller(process, nil, SnabbleUI.project)

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
        var orders = orderList.receipts.map { OrderEntry.done($0) }

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
        tableView.deselectRow(at: indexPath, animated: true)
        guard let orders = self.orders else {
            return
        }

        let orderEntry = orders[indexPath.row]
        guard case .done(let order) = orderEntry else {
            return
        }

        spinner.startAnimating()
        tableView.allowsSelection = false

        let project = SnabbleAPI.project(for: order.projectId) ?? SnabbleAPI.projects[0]
        showOrder(order, for: project) { [weak self] _ in
            self?.spinner.stopAnimating()
            tableView.allowsSelection = true
        }
    }
}

extension ReceiptsListViewController {
    func showOrder(_ order: Order, for project: Project, receiptReceived: @escaping (Result<URL, Error>) -> Void) {
        order.getReceipt(project) { [weak self] result in
            receiptReceived(result)

            switch result {
            case .success(let targetURL):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none

                let title = formatter.string(from: order.date)

                self?.showQuicklook(for: targetURL, with: title)
            case .failure(let error):
                Log.error("error saving receipt: \(error)")
            }
        }
    }

    private func showQuicklook(for url: URL, with title: String) {
        let receiptPreviewItem = ReceiptPreviewItem(url, title)
        let dataSource = QuicklookPreviewControllerDataSource(item: receiptPreviewItem)

        let previewController = QLPreviewController()
        previewController.dataSource = dataSource
        previewController.delegate = self
        navigationController?.pushViewController(previewController, animated: true)

        quickLookDataSources.append(dataSource)

        analyticsDelegate?.track(.viewReceiptDetail)
    }
}

final class QuicklookPreviewControllerDataSource: QLPreviewControllerDataSource {
    let item: QLPreviewItem

    init(item: QLPreviewItem) {
        self.item = item
    }

    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        item
    }
}

extension ReceiptsListViewController: QLPreviewControllerDelegate {
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        quickLookDataSources.removeAll {
            $0.item.isEqual(controller.currentPreviewItem)
        }
    }
}
