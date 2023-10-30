//
//  ReceiptsListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

#if SWIFTUI_RECEIPT
import SwiftUI
import Combine

public protocol ReceiptsListDelegate: AnyObject {
    func handleAction(_ viewController: ReceiptsListViewController, on receipt: PurchaseProviding) -> Bool
}

/// A UIViewController wrapping SwiftUI's ReceiptsListViewController
open class ReceiptsListViewController: UIHostingController<ReceiptsListScreen> {
    
    private var cancellables = Set<AnyCancellable>()
    public weak var delegate: ReceiptsListDelegate?
    public weak var analyticsDelegate: AnalyticsDelegate?
    public weak var detailDelegate: ReceiptsDetailViewControllerDelegate?

    public var viewModel: LastPurchasesViewModel {
        rootView.viewModel
    }
    
    public init() {
        let rootView = ReceiptsListScreen(projectId: Snabble.shared.projects.first?.id)

        super.init(rootView: rootView)

        viewModel.actionPublisher
            .sink { [unowned self] provider in
                self.actionFor(provider: provider)
            }
            .store(in: &cancellables)
        
        viewModel.$numberOfUnloaded
            .sink { [unowned self] value in
                self.tabBarItem.badgeValue = value > 0 ? "\(value)" : nil
                UIApplication.shared.applicationIconBadgeNumber = value
                self.view.setNeedsDisplay()
            }
            .store(in: &cancellables)
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func actionFor(provider: PurchaseProviding) {
        if !self.handleAction(self, on: provider) {
            let detailController = ReceiptsDetailViewController(orderId: provider.id, projectId: provider.projectId)
            detailController.delegate = detailDelegate
            detailController.analyticsDelegate = analyticsDelegate
            self.navigationController?.pushViewController(detailController, animated: true)
        }
    }
}

extension ReceiptsListViewController: ReceiptsListDelegate {
    public func handleAction(_ viewController: ReceiptsListViewController, on receipt: PurchaseProviding) -> Bool {
        return delegate?.handleAction(viewController, on: receipt) ?? false
    }
}

#else

public final class ReceiptsListViewController: UITableViewController {
    public final class EmptyView: UIView {
        private(set) weak var imageView: UIImage?
        private(set) weak var textLabel: UILabel?

        public override init(frame: CGRect) {
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72)
            let image = UIImage(systemName: "scroll", withConfiguration: symbolConfiguration)
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            let textLabel = UILabel()
            textLabel.text = Asset.localizedString(forKey: "Snabble.Receipts.noReceipts")
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            textLabel.numberOfLines = 0
            textLabel.textAlignment = .center
            textLabel.font = .preferredFont(forTextStyle: .body)
            textLabel.adjustsFontForContentSizeCategory = true

            super.init(frame: frame)

            addSubview(imageView)
            addSubview(textLabel)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: leadingAnchor, multiplier: 1),
                trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1),
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),

                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),

                imageView.topAnchor.constraint(equalTo: topAnchor),
                textLabel.topAnchor.constraint(equalToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 1),
                bottomAnchor.constraint(equalTo: textLabel.bottomAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private(set) weak var emptyView: EmptyView?
    private(set) weak var activityIndicator: UIActivityIndicatorView?

    private var orders: [Order] = [] {
        didSet {
            activityIndicator?.stopAnimating()
            emptyView?.isHidden = !orders.isEmpty

            tableView.reloadData()
        }
    }
    public weak var analyticsDelegate: AnalyticsDelegate?
    public weak var detailDelegate: ReceiptsDetailViewControllerDelegate?

    public init() {
        super.init(nibName: nil, bundle: nil)
        title = Asset.localizedString(forKey: "Snabble.Receipts.title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        let emptyView = EmptyView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        view.addSubview(emptyView)
        self.emptyView = emptyView

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

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyView.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: -16),
            emptyView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: emptyView.bottomAnchor, multiplier: 1)
        ])

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReceiptContentConfiguration.tableViewCellIdentifier)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        self.loadOrderList()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewReceiptList)
        self.tableView.flashScrollIndicators()
    }

    private func updateUnloadedReceipts(_ orderList: OrderList?) {
        guard let project = Snabble.shared.projects.first else {
            return
        }
        let unloaded = orderList?.numberOfUnloadedReceipts(project) ?? 0
        if unloaded > 0 {
            DispatchQueue.main.async {
                self.tabBarItem.badgeValue = "\(unloaded)"
                self.tabBarItem.badgeColor = .red
            }
        }
        UNUserNotificationCenter.current().requestAuthorization(options: .badge) { (granted, error) in
            if granted, error == nil {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = unloaded
                }
            }
        }
    }
    
    private func loadOrderList() {
        guard let project = Snabble.shared.projects.first else {
            return
        }
        OrderList.load(project) { [weak self] result in
            self?.orderListLoaded(result)
        }
    }

    private func orderListLoaded(_ result: Result<OrderList, SnabbleError>) {
        switch result {
        case .success(let orderList):
            self.orders = orderList.receipts
            self.updateUnloadedReceipts(orderList)
            
        case .failure:
            self.orders = []
            self.updateUnloadedReceipts(nil)
        }
    }

    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        guard let project = Snabble.shared.projects.first else {
            return
        }

        OrderList.load(project) { [weak self] result in
            sender.endRefreshing()
            self?.orderListLoaded(result)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ReceiptsListViewController {
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orders.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptContentConfiguration.tableViewCellIdentifier, for: indexPath)

        let order = orders[indexPath.row]
        var configuration = ReceiptContentConfiguration(order: order)
        configuration.showProjectImage = Snabble.shared.projects.count > 1
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]

        guard let project = Snabble.shared.project(for: order.projectId) ?? Snabble.shared.projects.first else {
            return
        }

        let detailViewController = ReceiptsDetailViewController(order: order, project: project)
        detailViewController.delegate = detailDelegate
        detailViewController.analyticsDelegate = analyticsDelegate
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
#endif
