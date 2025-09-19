//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley
import SnabbleCore
import SnabbleAssetProviding

final class ScannerDrawerViewController: UIViewController {
    private var shoppingList: ShoppingList?
    private var shoppingListTableVC: ScannerShoppingListViewController

    private let shoppingCart: ShoppingCart
    private var shoppingCartVC: ShoppingCartViewController
    
    private let projectId: Identifier<Project>

    weak var shoppingCartDelegate: ShoppingCartDelegate? {
        didSet {
            checkoutBar?.shoppingCartDelegate = shoppingCartDelegate
            shoppingCartVC.shoppingCartDelegate = shoppingCartDelegate
        }
    }

    weak var shoppingListDelegate: ShoppingListDelegate? {
        didSet {
            shoppingListTableVC.delegate = shoppingListDelegate
        }
    }

    private let minDrawerHeight: CGFloat = 86
    private let totalsHeight: CGFloat = 60
    private let cartItemHeight: CGFloat = 50
    private let listItemHeight: CGFloat = 50
    private let separatorSpacerHeight: CGFloat = 16
    private let innerSpacerHeight: CGFloat = 14
    private let segmentedControlHeight: CGFloat = 32

    private var segmentedControlHidden = true {
        didSet {
            segmentedControl?.isHidden = segmentedControlHidden
            innerSpacer?.isHidden = segmentedControlHidden
        }
    }

    private weak var checkoutBar: CheckoutBar?
    private var previousPosition = PulleyPosition.closed

    private weak var effectView: UIVisualEffectView?
    private weak var handleView: UIView?
    private weak var segmentedControl: UISegmentedControl?
    private weak var innerSpacer: UIView?
    private weak var bottomView: UIView?

    init(_ projectId: Identifier<Project>,
         shoppingCart: ShoppingCart
    ) {
        self.projectId = projectId
        self.shoppingCart = shoppingCart

        self.shoppingListTableVC = ScannerShoppingListViewController()
        self.shoppingCartVC = ShoppingCartViewController(shoppingCart: shoppingCart, compactMode: true)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)

        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let effectView = UIVisualEffectView()
        effectView.translatesAutoresizingMaskIntoConstraints = false

        let handleView = UIView()
        handleView.translatesAutoresizingMaskIntoConstraints = false
        handleView.layer.cornerRadius = 2.5
        handleView.layer.masksToBounds = true
        handleView.backgroundColor = .systemGray3
        handleView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        handleView.addGestureRecognizer(tap)

        let checkoutBar = CheckoutBar(self, shoppingCart)
        let segmentedControl = UISegmentedControl(items: [Asset.localizedString(forKey: "Snabble.ShoppingList.title"), Asset.localizedString(forKey: "Snabble.ShoppingCart.title")])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)

        let wrapperStackView = UIStackView(arrangedSubviews: [checkoutBar, segmentedControl])
        wrapperStackView.translatesAutoresizingMaskIntoConstraints = false
        wrapperStackView.axis = .vertical
        wrapperStackView.distribution = .fill
        wrapperStackView.alignment = .fill
        wrapperStackView.spacing = 14

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator

        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(effectView)
        contentView.addSubview(handleView)
        contentView.addSubview(wrapperStackView)
        contentView.addSubview(separator)
        contentView.addSubview(bottomView)

        self.effectView = effectView
        self.checkoutBar = checkoutBar
        self.segmentedControl = segmentedControl
        self.bottomView = bottomView

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            handleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            handleView.heightAnchor.constraint(equalToConstant: 6),

            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).usingPriority(.defaultHigh + 1),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).usingPriority(.defaultHigh + 1),
            wrapperStackView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 4).usingPriority(.defaultHigh + 1),

            checkoutBar.leadingAnchor.constraint(equalTo: wrapperStackView.leadingAnchor).usingPriority(.defaultHigh + 1),
            checkoutBar.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor).usingPriority(.defaultHigh + 1),

            segmentedControl.heightAnchor.constraint(equalToConstant: segmentedControlHeight).usingPriority(.defaultHigh + 1),

            separator.topAnchor.constraint(equalTo: wrapperStackView.bottomAnchor, constant: 16),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).usingPriority(.defaultHigh),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bottomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            bottomView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])

        self.view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up appearance for translucency effect
        view.backgroundColor = .clear
        self.shoppingListTableVC.view.backgroundColor = .clear
        self.shoppingCartVC.view.backgroundColor = .clear

        checkoutBar?.shoppingCartDelegate = shoppingCartDelegate

        self.bottomViewSwitchTo(shoppingListTableVC, duration: 0)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)
      
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, _: UITraitCollection) in
            self.setupBlurEffect(forTraitCollection: self.traitCollection)
        })
   }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        setupBlurEffect(forTraitCollection: traitCollection)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateShoppingLists()
        checkoutBar?.updateSelectionVisibility()
        checkoutBar?.updateTotals()
    }

    private func setupBlurEffect(forTraitCollection traitCollection: UITraitCollection) {
        effectView?.effect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .light ? .extraLight : .dark)
    }

    @objc private func handleTapped(_ gesture: UITapGestureRecognizer) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }

    @objc private func tabChanged(_ control: UISegmentedControl) {
        selectSegment(control.selectedSegmentIndex)
    }

    func bottomViewSwitchTo(_ destination: UIViewController, duration: TimeInterval = 0.15) {
        guard destination != children.first else { return }
        guard let bottomView = bottomView else { return }
        if let source = self.children.first {
            addChild(destination)
            source.willMove(toParent: nil)
            transition(from: source,
                       to: destination,
                       duration: duration,
                       options: .transitionCrossDissolve,
                       animations: {},
                       completion: { _ in
                           source.removeFromParent()
                           destination.didMove(toParent: self)
                       }
            )
        } else {
            addChild(destination)
            view.addSubview(destination.view)
            destination.didMove(toParent: self)
        }

        destination.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            destination.view.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            destination.view.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
            destination.view.topAnchor.constraint(equalTo: bottomView.topAnchor),
            destination.view.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor)
        ])
    }

    private func updateShoppingLists() {
        let shoppingLists = ShoppingList.fetchListsFromDisk()
        shoppingList = shoppingLists.first { $0.projectId == projectId }
        if shoppingList?.isEmpty == true {
            shoppingList = nil
        }

        shoppingListTableVC.reload(shoppingList)
        setupViews(shoppingList, shoppingCart)
    }

    private func setupViews(_ list: ShoppingList?, _ cart: ShoppingCart?) {
        let noList = list == nil
        segmentedControlHidden = noList
        if noList {
            selectSegment(1)
        }
    }

    func markScannedProduct(_ product: Product) {
        shoppingListTableVC.markScannedProduct(product)
    }

    func selectSegment(_ segment: Int) {
        segmentedControl?.selectedSegmentIndex = segment
        let activeVC: UIViewController
        if segment == 0 {
            activeVC = self.shoppingListTableVC
        } else {
            activeVC = self.shoppingCartVC
        }

        self.bottomViewSwitchTo(activeVC)
    }

    @objc private func shoppingCartUpdated(_ notification: Notification) {
        checkoutBar?.updateTotals(updating: notification.object is ShoppingCartViewModel)
    }

    func updateTotals() {
        checkoutBar?.updateTotals()
    }
}

// MARK: - pulley
extension ScannerDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.compact
    }

    public func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let heightForCartItems: CGFloat = min(CGFloat(shoppingCart.items.count) * cartItemHeight, cartItemHeight * 2.5)
        let heightForListItems: CGFloat = min(CGFloat(shoppingList?.count ?? 0) * listItemHeight, listItemHeight * 2.5)
        let heightForItems = !shoppingCart.items.isEmpty ? heightForCartItems : heightForListItems

        let heightForSegmentedControl = shoppingList == nil ? 0 : segmentedControlHeight + separatorSpacerHeight
        return minDrawerHeight + heightForSegmentedControl + totalsHeight + heightForItems + bottomSafeArea
    }

    public func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        let newPosition = drawer.drawerPosition
        shoppingListTableVC.tableView.isScrollEnabled = newPosition == .open

        if newPosition != previousPosition {
            let scanner = self.pulleyViewController?.primaryContentViewController as? ScanningViewController
            if previousPosition == .open {
                scanner?.resumeScanning()
            } else if newPosition == .open {
                scanner?.pauseScanning()
            }
            previousPosition = drawer.drawerPosition
        }
    }

    public func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        updateOverlay(on: drawer, forDistance: distance)
    }

    private func updateOverlay(on drawer: PulleyViewController, forDistance distance: CGFloat) {
        let scanner = drawer.primaryContentViewController as? ScanningViewController
        let offset = -min(distance, view.bounds.height * 0.8) / 2
        scanner?.setOverlayOffset(offset)
    }
}

extension ScannerDrawerViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        self.shoppingCartDelegate?.track(event)
    }
}
