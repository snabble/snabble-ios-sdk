//
//  ReceiptsDetailViewController.swift
//  
//
//  Created by Uwe Tilemann on 09.11.22.
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

public final class ReceiptsDetailViewController: QLPreviewController {
    private var quickLookDataSources: [QuicklookPreviewControllerDataSource] = []
    
    deinit {
        quickLookDataSources = []
    }
}

extension ReceiptsDetailViewController {
    public func getReceipt(orderID: String, projectID: Identifier<Project>, receiptReceived: @escaping (Result<URL, Error>) -> Void) {
        guard let project = Snabble.shared.project(for: projectID) ?? Snabble.shared.projects.first else {
            return
        }

        OrderList.load(project) { [weak self] result in
            if let order: SnabbleCore.Order = try? result.get().receipts.filter({ order in
                order.projectId == project.id && order.id == orderID
            }).first {
                self?.getReceipt(order: order, project: project, receiptReceived: receiptReceived)
            }
        }
    }
    
    public func getReceipt(order: Order, project: Project, receiptReceived: @escaping (Result<URL, Error>) -> Void) {
        order.getReceipt(project) { [weak self] result in

            switch result {
            case .success(let targetURL):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none

                let title = formatter.string(from: order.date)

                self?.setupQuicklook(for: targetURL, with: title)
            case .failure(let error):
                Log.error("error saving receipt: \(error)")
            }
            
            receiptReceived(result)
        }
    }

    private func setupQuicklook(for url: URL, with title: String) {
        let receiptPreviewItem = ReceiptPreviewItem(url, title)
        let dataSource = QuicklookPreviewControllerDataSource(item: receiptPreviewItem)

        self.dataSource = dataSource
        self.delegate = self

        quickLookDataSources.append(dataSource)
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

extension ReceiptsDetailViewController: QLPreviewControllerDelegate {
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        quickLookDataSources.removeAll {
            $0.item.isEqual(controller.currentPreviewItem)
        }
    }
}
