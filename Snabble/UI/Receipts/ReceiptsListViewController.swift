//
//  ReceiptsListViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
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

// TODO: add pull-to-refresh
@objc(ReceiptsListViewController)
public final class ReceiptsListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var orderList: OrderList?
    private var quickLook = QLPreviewController()
    private var previewItem: QLPreviewItem!

    public init() {
        super.init(nibName: nil, bundle: Snabble.bundle)

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
        }
    }

    private func orderListLoaded(_ result: Result<OrderList, SnabbleError>) {
        switch result {
        case .success(let orders):
            self.orderList = orders
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                if self.orderList?.orders.count == 0 {
                    self.emptyLabel.isHidden = false
                }
                self.tableView.reloadData()
            }

        case .failure:
            // TODO: display error msg
            break
        }
    }
}

extension ReceiptsListViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orderList?.orders.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell") ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: "receiptCell")
            c.accessoryType = .disclosureIndicator
            c.selectionStyle = .none
            return c
        }()

        guard
            let order = self.orderList?.orders[indexPath.row],
            let project = SnabbleAPI.projectFor(order.project)
        else {
            return cell
        }

        cell.textLabel?.text = order.shopName
        let formatter = PriceFormatter(project)
        let price = formatter.format(order.price)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: order.date)
        cell.detailTextLabel?.text = "\(price) - \(date) Uhr"

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.spinner.isAnimating {
            return
        }
        
        guard
            let order = self.orderList?.orders[indexPath.row],
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
