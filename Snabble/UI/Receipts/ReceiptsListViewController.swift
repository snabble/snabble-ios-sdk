//
//  ReceiptsListViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit
import QuickLook

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL? {
        return self.receipt.pdfPath
    }

    var previewItemTitle: String? { return "Beleg" }

    private let receipt: ReceiptData

    init(_ receipt: ReceiptData) {
        self.receipt = receipt
        super.init()
    }
}

extension ReceiptData {
    var previewItem: PreviewItem {
        return PreviewItem(self)
    }
}

public class ReceiptsListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private var receipts = [ReceiptData]()
    private var quickLook = QLPreviewController()

    public init() {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.title = "Belege"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.quickLook.dataSource = self
        self.quickLook.delegate = self

        self.receipts = ReceiptsManager.shared.listReceipts()
    }
}

extension ReceiptsListViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.receipts.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell") ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: "receiptCell")
            c.accessoryType = .disclosureIndicator
            c.selectionStyle = .none
            return c
        }()

        let receipt = self.receipts[indexPath.row]
        cell.textLabel?.text = receipt.shopName
        let price = PriceFormatter.format(receipt.total)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let date = formatter.string(from: receipt.date)
        cell.detailTextLabel?.text = "\(price) - \(date) Uhr"

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.quickLook.currentPreviewItemIndex = indexPath.row
        self.navigationController?.pushViewController(self.quickLook, animated: true)
    }
}

extension ReceiptsListViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.receipts.count
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.receipts[index].previewItem
    }
}
