//
//  CheckoutStepsViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.10.21.
//

import Foundation
import UIKit

public final class CheckoutStepsViewController: UIViewController {
    private(set) weak var tableView: UITableView?
    private(set) weak var headerView: CheckoutHeaderView?
    private(set) weak var doneButton: UIButton?

    private weak var ratingViewController: CheckoutRatingViewController?

    public weak var paymentDelegate: PaymentDelegate?

    private weak var checksViewController: CheckoutChecksViewController?

    private typealias ItemIdentifierType = CheckoutStep
    private typealias CellProvider = (_ tableView: UITableView, _ indexPath: IndexPath, _ itemIdentifier: ItemIdentifierType) -> UITableViewCell?

    private var cellProvider: CellProvider = { tableView, indexPath, step in
        switch step.kind {
        case .default:
            let cell = tableView.dequeueReusable(CheckoutStepTableViewCell.self, for: indexPath)
            cell.stepView?.configure(with: step)
            return cell

        case .information:
            let cell = tableView.dequeueReusable(CheckoutInformationTableViewCell.self, for: indexPath)
            cell.informationView?.configure(with: step)
            return cell
        }
    }

    private lazy var arrayDataSource = UITableViewViewArrayDataSource<ItemIdentifierType>(
        tableView: tableView!,
        cellProvider: cellProvider
    )

    @available(iOS 13.0, *)
    private lazy var diffableDataSource = UITableViewDiffableDataSource<Int, ItemIdentifierType>(
        tableView: tableView!,
        cellProvider: cellProvider
    )

    let viewModel: CheckoutStepsViewModel
    public var shop: Shop {
        viewModel.shop
    }

    public var checkoutProcess: CheckoutProcess {
        viewModel.checkoutProcess
    }

    public var shoppingCart: ShoppingCart {
        viewModel.shoppingCart
    }

    private weak var processTimer: Timer?
    private var processSessionTask: URLSessionDataTask?

    public init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        viewModel = CheckoutStepsViewModel(
            shop: shop,
            checkoutProcess: checkoutProcess,
            shoppingCart: shoppingCart
        )

        super.init(nibName: nil, bundle: nil)

        viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let style: UITableView.Style
        if #available(iOS 13.0, *) {
            style = .insetGrouped
        } else {
            style = .grouped
        }
        let tableView = UITableView(frame: view.bounds, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 44
        tableView.register(CheckoutStepTableViewCell.self)
        tableView.register(CheckoutInformationTableViewCell.self)
        tableView.allowsSelection = false
        tableView.contentInset = .init(top: 0, left: 0, bottom: 48 + 16 + 16, right: 0)

        view.addSubview(tableView)
        self.tableView = tableView

        let headerView = CheckoutHeaderView()
        tableView.tableHeaderView = headerView
        self.headerView = headerView

        let ratingViewController = CheckoutRatingViewController(shop: shop)
        ratingViewController.shouldRequestReview = false
        ratingViewController.analyticsDelegate = paymentDelegate
        addChild(ratingViewController)
        tableView.tableFooterView = ratingViewController.view
        ratingViewController.didMove(toParent: self)
        self.ratingViewController = ratingViewController

        let doneButton = UIButton(type: .system)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle(L10n.Snabble.done, for: .normal)
        doneButton.makeSnabbleButton()
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        doneButton.addTarget(self, action: #selector(doneButtonTouchedUpInside(_:)), for: .touchUpInside)
        view.addSubview(doneButton)
        self.doneButton = doneButton

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),

            tableView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: doneButton.trailingAnchor, constant: 24),

            doneButton.heightAnchor.constraint(equalToConstant: 48),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = checkoutProcess.rawPaymentMethod?.title ?? L10n.Snabble.Payment.confirm
        headerView?.configure(with: viewModel.headerViewModel)
        tableView?.updateHeaderViews()

        if #available(iOS 13.0, *) {
            tableView?.dataSource = diffableDataSource
        } else {
            tableView?.dataSource = arrayDataSource
        }
        update(with: viewModel.steps, animate: false)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startTimer()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let analyticsEvent = checkoutProcess.rawPaymentMethod?.analyticsEvent {
            paymentDelegate?.track(analyticsEvent)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopTimer()
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView?.updateHeaderViews()
    }

    @objc private func doneButtonTouchedUpInside(_ sender: UIButton) {
        SnabbleAPI.fetchAppUserData(shop.projectId)
        updateShoppingCart(for: checkoutProcess)
        navigationController?.popToRootViewController(animated: true)
        paymentDelegate?.track(.checkoutStepsClosed)
    }

    private func updateShoppingCart(for checkoutProcess: CheckoutProcess) {
        switch checkoutProcess.paymentState {
        case .successful:
            shoppingCart.removeAll(endSession: true, keepBackup: false)
        default:
            shoppingCart.generateNewUUID()
        }
    }

    private func update(with steps: [ItemIdentifierType], animate: Bool = true) {
        if #available(iOS 13.0, *), let dataSource = tableView?.dataSource as? UITableViewDiffableDataSource<Int, ItemIdentifierType> {
            var snapshot = NSDiffableDataSourceSnapshot<Int, ItemIdentifierType>()
            snapshot.appendSections([0])
            snapshot.appendItems(steps, toSection: 0)
            dataSource.apply(snapshot, animatingDifferences: animate)
        } else if let dataSource = tableView?.dataSource as? UITableViewViewArrayDataSource<ItemIdentifierType> {
            dataSource.apply(steps)
        } else {
            fatalError("dataSource cannot be updated")
        }
    }
}

extension CheckoutStepsViewController: CheckoutStepsViewModelDelegate {
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateCheckoutProcess checkoutProcess: CheckoutProcess) {
        if isCheckNeeded(for: checkoutProcess) {
            let viewController = CheckoutChecksViewController(qrCodeContent: checkoutProcess.id)
            addChild(viewController)
            viewController.view.frame = view.bounds
            view.addSubview(viewController.view)
            viewController.didMove(toParent: self)
            self.checksViewController = viewController
        } else {
            checksViewController?.willMove(toParent: nil)
            checksViewController?.view.removeFromSuperview()
            checksViewController?.removeFromParent()
        }
    }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateSteps steps: [CheckoutStep]) {
        update(with: steps, animate: true)
    }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateHeaderViewModel headerViewModel: CheckoutHeaderViewModel) {
        headerView?.configure(with: headerViewModel)
    }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateExitToken exitToken: ExitToken) {
        paymentDelegate?.exitToken(exitToken, for: shop)
    }

    // MARK: Checks
    private func isCheckNeeded(for checkoutProcess: CheckoutProcess) -> Bool {
        let checksNeedingSupervisor = checkoutProcess.checks.filter { $0.performedBy == .supervisor }
        return checkoutProcess.supervisorApproval == nil || !checksNeedingSupervisor.isEmpty
    }
}

private extension UITableView {
    func updateHeaderViews() {
        updateHeaderViewHeight(for: tableHeaderView)
        updateHeaderViewHeight(for: tableFooterView)
    }

    func updateHeaderViewHeight(for header: UIView?) {
        guard let header = header else { return }
        let fittingSize = CGSize(width: bounds.width - (safeAreaInsets.left + safeAreaInsets.right), height: 0)
        header.frame.size = header.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
}

private extension RawPaymentMethod {
    var title: String {
        switch self {
        case .qrCodePOS:
            return L10n.Snabble.QRCode.title
        default:
            return L10n.Snabble.Payment.confirm
        }
    }

    var analyticsEvent: AnalyticsEvent {
        switch self {
        case .gatekeeperTerminal:
            return .viewTerminalCheckout
        case .qrCodePOS:
            return .viewQRCodeCheckout
        case .applePay:
            return .viewApplePayCheckout
        default:
            return .viewOnlineCheckout
        }
    }
}
