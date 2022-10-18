//
//  ReceiptsListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import QuickLook
import SnabbleCore

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

public final class ReceiptsListViewController: UITableViewController {
    private let emptyLabel = UILabel()
    private weak var activityIndicator: UIActivityIndicatorView?

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

        super.init(nibName: nil, bundle: nil)

        self.title = Asset.localizedString(forKey: "Snabble.Receipts.title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true
        view.addSubview(emptyLabel)

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemGray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        self.activityIndicator = activityIndicator

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        self.tableView.register(ReceiptCell.self, forCellReuseIdentifier: "receiptCell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.emptyLabel.text = Asset.localizedString(forKey: "Snabble.Receipts.noReceipts")
        self.emptyLabel.isHidden = true

        self.loadOrderList()
        self.startReceiptPolling()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewReceiptList)
        self.tableView.flashScrollIndicators()
    }

    private func loadOrderList() {
        guard let project = Snabble.shared.projects.first else {
            return
        }

        OrderList.load(project) { result in
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

        let poller = PaymentProcessPoller(process, SnabbleCI.project)

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
                let pending = OrderEntry.pending(SnabbleCI.project.name, SnabbleCI.project.id)
                orders.insert(pending, at: 0)
            }
        }
        self.orders = orders

        self.activityIndicator?.stopAnimating()
        if orders.isEmpty {
            self.emptyLabel.isHidden = false
        }
        self.tableView.reloadData()
    }

    @objc private func handleRefresh(_ sender: Any) {
        guard let project = Snabble.shared.projects.first else {
            return
        }

        OrderList.load(project) { result in
            self.tableView.refreshControl?.endRefreshing()
            self.orderListLoaded(result)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ReceiptsListViewController {
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orders?.count ?? 0
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell", for: indexPath) as! ReceiptCell

        guard let orders = self.orders else {
            return UITableViewCell(style: .default, reuseIdentifier: "invalidCell")
        }

        let orderEntry = orders[indexPath.row]
        cell.show(orderEntry)

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let orders = self.orders else {
            return
        }

        let orderEntry = orders[indexPath.row]
        guard
            case .done(let order) = orderEntry,
            let project = Snabble.shared.project(for: order.projectId) ?? Snabble.shared.projects.first
        else {
            return
        }

        activityIndicator?.startAnimating()
        tableView.allowsSelection = false
        showOrder(order, for: project) { [weak self] _ in
            self?.activityIndicator?.stopAnimating()
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