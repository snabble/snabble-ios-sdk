//
//  ReceiptsListViewController.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit
import QuickLook

final class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL? {
        return self.receiptUrl
    }

    var previewItemTitle: String? { return "Beleg" }

    private let receiptUrl: URL

    init(_ receiptUrl: URL) {
        self.receiptUrl = receiptUrl
        super.init()
    }
}

enum OrderEntry {
    case pending(String)    // shop name
    case done(Order)
}

@objc(ReceiptsListViewController)
public final class ReceiptsListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var quickLook = QLPreviewController()
    private var previewItem: QLPreviewItem!

    private var orders = [OrderEntry]()
    private var process: CheckoutProcess?

    convenience init() {
        self.init(nil)
    }

    public init(_ process: CheckoutProcess?) {
        self.process = process
        
        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Receipts.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.quickLook.dataSource = self
        self.quickLook.delegate = self

        self.emptyLabel.text = "Snabble.Receipts.noReceipts".localized()
        self.emptyLabel.isHidden = true

        self.spinner.startAnimating()
        ClientOrders.loadList { result in
            self.orderListLoaded(result)
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
            self.tableView.refreshControl = refreshControl
        }
    }

    private func orderListLoaded(_ result: Result<OrderList, SnabbleError>) {
        switch result {
        case .success(let orderList):
            self.orders = orderList.orders.map { OrderEntry.done($0) }

            #warning("add real check")
            let pending = OrderEntry.pending("Knauber Freizeitmarkt")
            self.orders.insert(pending, at: 0)

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                if self.orders.count == 0 {
                    self.emptyLabel.isHidden = false
                }
                self.tableView.reloadData()
            }

        case .failure:
            // TODO: display error msg
            break
        }
    }

    @objc private func handleRefresh(_ sender: Any) {
        ClientOrders.loadList { result in
            self.tableView.refreshControl?.endRefreshing()
            self.orderListLoaded(result)
        }
    }

    private func checkReceipt(_ shop: Shop) {
        guard let process = self.process else {
            return
        }

        let poller = PaymentProcessPoller(process, SnabbleUI.project, shop)

        poller.waitForReceipt { available in
            print("receipt poller: \(available)")
        }
    }

}

extension ReceiptsListViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orders.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell") ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: "receiptCell")
            c.accessoryType = .disclosureIndicator
            c.selectionStyle = .none
            return c
        }()

        let orderEntry = self.orders[indexPath.row]

        switch orderEntry {
        case .done(let order):
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = order.shopName
            cell.detailTextLabel?.text = ""

            guard let project = SnabbleAPI.projectFor(order.project) else {
                break
            }

            let formatter = PriceFormatter(project)
            let price = formatter.format(order.price)

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: order.date)
            cell.detailTextLabel?.text = "\(price) - \(date) Uhr"

        case .pending(let shopName):
            cell.textLabel?.text = shopName
            cell.detailTextLabel?.text = "(wird geladen)"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.spinner.isAnimating {
            return
        }

        let orderEntry = self.orders[indexPath.row]
        guard
            case .done(let order) = orderEntry,
            let project = SnabbleAPI.projectFor(order.project)
        else {
            return
        }

        self.showOrder(order, project)
    }
}

extension ReceiptsListViewController {
    func showOrder(_ order: Order, _ project: Project) {
        let fileManager = FileManager.default
        let cacheDir = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let targetPath = cacheDir.appendingPathComponent("snabble-order-\(order.id).pdf")

        try? fileManager.removeItem(at: targetPath)

        if fileManager.fileExists(atPath: targetPath.path) {
            self.showQuicklook(targetPath)
        } else {
            self.downloadAndShow(order, project, targetPath)
        }
    }

    func downloadAndShow(_ order: Order, _ project: Project, _ targetPath: URL) {
        self.spinner.startAnimating()
        project.request(.get, order.links.receipt.href, timeout: 10) { request in
            guard let request = request else {
                self.spinner.stopAnimating()
                return
            }

            let session = SnabbleAPI.urlSession()
            let task = session.downloadTask(with: request) { location, response, error in
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                }

                guard let location = location else {
                    Log.error("error downloading receipt: \(String(describing: error))")
                    return
                }

                do {
                    try FileManager.default.moveItem(at: location, to: targetPath)
                    DispatchQueue.main.async {
                        self.showQuicklook(targetPath)
                    }
                } catch {
                    Log.error("error saving receipt: \(error)")
                }
            }
            task.resume()
        }
    }

    func showQuicklook(_ url: URL) {
        self.quickLook.currentPreviewItemIndex = 0
        self.previewItem = PreviewItem(url)
        self.navigationController?.pushViewController(self.quickLook, animated: true)
        self.quickLook.reloadData()
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
