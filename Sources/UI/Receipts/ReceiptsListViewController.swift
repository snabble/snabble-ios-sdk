//
//  ReceiptsListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

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

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "receiptCell")
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
        case .failure:
            self.orders = []
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiptCell", for: indexPath)

        let order = orders[indexPath.row]
        var configuration = ReceiptContentConfiguration(order: order)
        configuration.showProjectImage = Snabble.shared.projects.count > 1
        cell.contentConfiguration = configuration
        cell.accessoryType = configuration.accessoryType

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = self.orders[indexPath.row]

        guard let project = Snabble.shared.project(for: order.projectId) ?? Snabble.shared.projects.first else {
            return
        }

        activityIndicator?.startAnimating()
        tableView.allowsSelection = false

        let detailViewController = ReceiptsDetailViewController()

        detailViewController.getReceipt(order: order, project: project) { [weak self] result in
            self?.activityIndicator?.stopAnimating()
            tableView.allowsSelection = true
            
            switch result {
            case .success:
                self?.navigationController?.pushViewController(detailViewController, animated: true)
                self?.analyticsDelegate?.track(.viewReceiptDetail)
            case .failure:
                break
            }
        }
    }
}
