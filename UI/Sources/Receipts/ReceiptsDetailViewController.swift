//
//  ReceiptsDetailViewController.swift
//  
//
//  Created by Uwe Tilemann on 09.11.22.
//

import UIKit
import QuickLook
import SnabbleCore

public final class ReceiptPreviewItem: NSObject, QLPreviewItem, Sendable {
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

public protocol ReceiptsDetailViewControllerDelegate: AnyObject {
    func receiptsDetailViewController(_ viewController: ReceiptsDetailViewController, wantsActionsWithOrder order: Order, localURL: URL)
}

public final class ReceiptsDetailViewController: UIViewController {
    enum Error: Swift.Error {
        case missingProject
        case missingOrder
    }

    public weak var delegate: ReceiptsDetailViewControllerDelegate?

    public let orderId: String
    public let projectId: Identifier<Project>

    public private(set) var order: Order?
    public private(set) var project: Project?

    public private(set) var quickLookDataSources: QuicklookPreviewControllerDataSource?

    public weak var analyticsDelegate: AnalyticsDelegate?

    private(set) weak var activityIndicatorView: UIActivityIndicatorView?

    private(set) weak var previewController: QLPreviewController?
    private(set) weak var previewLayoutGuide: UILayoutGuide!

    public init(orderId: String, projectId: Identifier<Project>) {
        self.orderId = orderId
        self.order = nil
        self.projectId = projectId
        self.project = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(order: Order, project: Project) {
        self.order = order
        self.orderId = order.id
        self.projectId = project.id
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        quickLookDataSources = nil
    }

    public override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView

        let previewLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(previewLayoutGuide)
        self.previewLayoutGuide = previewLayoutGuide

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),

            view.topAnchor.constraint(equalTo: previewLayoutGuide.topAnchor),
            view.bottomAnchor.constraint(equalTo: previewLayoutGuide.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: previewLayoutGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: previewLayoutGuide.trailingAnchor)
        ])

        self.view = view
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let completion: @Sendable (Result<ReceiptPreviewItem, Swift.Error>) -> Void = { [weak self] result in
            Task { @MainActor in
                self?.activityIndicatorView?.stopAnimating()
                switch result {
                case .success(let previewItem):
                    self?.title = previewItem.title
                    self?.setupQuicklook(with: previewItem)
                case .failure:
                    print("Show Error!") // No requirements available
                }
            }
        }
        if let order, let project {
            getReceipt(order: order, project: project, completion: completion)
        } else {
            getReceipt(orderID: orderId, projectID: projectId, completion: completion)
        }
    }

    @objc func rightBarButtonItemTouchedUpInside(_ sender: UIBarButtonItem) {
        guard let order = order, let orderURL = quickLookDataSources?.item.previewItemURL else {
            return
        }
        delegate?.receiptsDetailViewController(self, wantsActionsWithOrder: order, localURL: orderURL)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analyticsDelegate?.track(.viewReceiptDetail)
    }
}

extension ReceiptsDetailViewController {
    private func getReceipt(orderID: String, projectID: Identifier<Project>, completion: @escaping @Sendable (Result<ReceiptPreviewItem, Swift.Error>) -> Void) {
        guard let project = Snabble.shared.project(for: projectID) ?? Snabble.shared.projects.first else {
            return completion(.failure(Error.missingProject))
        }

        OrderList.load(project) { [weak self] result in
            guard let order: SnabbleCore.Order = try? result.get().receipts.filter({ order in
                order.projectId == project.id && order.id == orderID
            }).first else {
                return completion(.failure(Error.missingOrder))
            }
            Task { @MainActor in
                self?.order = order
                self?.project = project
                self?.getReceipt(order: order, project: project, completion: completion)
            }
        }
    }
    
    private func getReceipt(order: Order, project: Project, completion: @escaping @Sendable (Result<ReceiptPreviewItem, Swift.Error>) -> Void) {
        order.getReceipt(project) { result in
            switch result {
            case .success(let targetURL):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                let title = formatter.string(from: order.date)
                completion(.success(ReceiptPreviewItem(targetURL, title)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func setupQuicklook(with previewItem: ReceiptPreviewItem) {
        let dataSource = QuicklookPreviewControllerDataSource(item: previewItem)

        let previewController = QLPreviewController()
        previewController.dataSource = dataSource
        addChild(previewController)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewController.view)
        previewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            previewLayoutGuide.topAnchor.constraint(equalTo: previewController.view.topAnchor),
            previewLayoutGuide.bottomAnchor.constraint(equalTo: previewController.view.bottomAnchor),
            previewLayoutGuide.leadingAnchor.constraint(equalTo: previewController.view.leadingAnchor),
            previewLayoutGuide.trailingAnchor.constraint(equalTo: previewController.view.trailingAnchor)
        ])
        self.previewController = previewController
        self.quickLookDataSources = dataSource

        showRightBarButtonItemIfPossible(previewItem: previewItem)
    }

    private func showRightBarButtonItemIfPossible(previewItem: QLPreviewItem) {
        if delegate != nil && QLPreviewController.canPreview(previewItem) {
            let barbuttonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(rightBarButtonItemTouchedUpInside(_:)))
            navigationItem.rightBarButtonItem = barbuttonItem
        }
    }
}

public final class QuicklookPreviewControllerDataSource: QLPreviewControllerDataSource {
    public let item: QLPreviewItem

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
