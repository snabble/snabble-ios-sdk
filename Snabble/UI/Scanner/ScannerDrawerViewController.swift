//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley
import AutoLayout_Helper

final class ScannerDrawerViewController: UIViewController {
    private var shoppingList: ShoppingList?
    private var shoppingListTableVC: ScannerShoppingListViewController

    private let shoppingCart: ShoppingCart
    private var shoppingCartVC: ShoppingCartTableViewController

    private let projectId: Identifier<Project>

    private var customAppearance: CustomAppearance?

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

    private let minDrawerHeight: CGFloat = 50
    private let totalsHeight: CGFloat = 60
    private let segmentedControlHeight: CGFloat = 48
    private let cartItemHeight: CGFloat = 50
    private let listItemHeight: CGFloat = 50

    private var checkoutBar: CheckoutBar?
    private var previousPosition = PulleyPosition.closed

    @IBOutlet private var effectView: UIVisualEffectView!
    @IBOutlet private var handleContainer: UIView!
    @IBOutlet private var handle: UIView!
    @IBOutlet private var checkoutWrapper: UIView!

    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var innerSpacer: UIView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var separatorHeight: NSLayoutConstraint!

    init(_ projectId: Identifier<Project>,
         shoppingCart: ShoppingCart
    ) {
        self.projectId = projectId
        self.shoppingCart = shoppingCart

        self.shoppingListTableVC = ScannerShoppingListViewController()
        self.shoppingCartVC = ShoppingCartTableViewController(shoppingCart)

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up appearance for translucency effect
        view.backgroundColor = .clear
        self.shoppingListTableVC.view.backgroundColor = .clear
        self.shoppingCartVC.view.backgroundColor = .clear
        setupBlurEffect()

        handle.layer.cornerRadius = 2.5
        handle.layer.masksToBounds = true
        handle.backgroundColor = .systemGray3
        handle.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        handle.addGestureRecognizer(tap)

        segmentedControl.setTitle(L10n.Snabble.ShoppingList.title, forSegmentAt: 0)
        segmentedControl.setTitle(L10n.Snabble.ShoppingCart.title, forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)

        let checkoutBar = CheckoutBar(self, shoppingCart)
        checkoutBar.shoppingCartDelegate = shoppingCartDelegate
        checkoutBar.translatesAutoresizingMaskIntoConstraints = false
        self.checkoutWrapper.addSubview(checkoutBar)
        NSLayoutConstraint.activate(
            checkoutBar.constraintsForAnchoringTo(boundsOf: checkoutWrapper)
        )
        self.checkoutBar = checkoutBar

        self.separatorHeight.constant = 1 / UIScreen.main.scale

        self.switchTo(shoppingListTableVC, in: contentView, duration: 0)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let custom = self.customAppearance {
            checkoutBar?.setCustomAppearance(custom)
        }

        self.updateShoppingLists()
        checkoutBar?.updateSelectionVisibility()
        checkoutBar?.updateTotals()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkoutBar?.barDidAppear()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupBlurEffect()
        if let customAppearance = self.customAppearance {
            self.checkoutBar?.setCustomAppearance(customAppearance)
        }
    }

    private func setupBlurEffect() {
        self.effectView.effect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .light ? .extraLight : .dark)
    }

    @objc private func handleTapped(_ gesture: UITapGestureRecognizer) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }

    @objc private func tabChanged(_ control: UISegmentedControl) {
        selectSegment(control.selectedSegmentIndex)
    }

    func switchTo(_ destination: UIViewController, in view: UIView, duration: TimeInterval = 0.15) {
        guard destination != children.first else {
            return
        }

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
            destination.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            destination.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            destination.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            destination.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func updateShoppingLists() {
        let shoppingLists = ShoppingList.fetchListsFromDisk()
        shoppingList = shoppingLists.first { $0.projectId == projectId }
        if shoppingList?.isEmpty == true {
            shoppingList = nil
        }

        shoppingListTableVC.reload(shoppingList)
        setupStackView(shoppingList, shoppingCart)
    }

    private func setupStackView(_ list: ShoppingList?, _ cart: ShoppingCart?) {
        let noList = list == nil
        segmentedControl?.isHidden = noList
        innerSpacer?.isHidden = noList
        if noList {
            selectSegment(1)
        }
    }

    func markScannedProduct(_ product: Product) {
        shoppingListTableVC.markScannedProduct(product)
    }

    func selectSegment(_ segment: Int) {
        segmentedControl.selectedSegmentIndex = segment
        let activeVC: UIViewController
        if segment == 0 {
            activeVC = self.shoppingListTableVC
        } else {
            activeVC = self.shoppingCartVC
        }

        self.switchTo(activeVC, in: contentView)
    }

    @objc private func shoppingCartUpdated(_ notification: Notification) {
        checkoutBar?.updateTotals()
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

        let heightForSegmentedControl = shoppingList == nil ? 0 : self.segmentedControlHeight
        return self.minDrawerHeight + heightForSegmentedControl + totalsHeight + heightForItems
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
        let height = self.view.bounds.height
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height - distance, right: 0)
        shoppingListTableVC.insets = insets
        shoppingCartVC.insets = insets

        let scanner = self.pulleyViewController?.primaryContentViewController as? ScanningViewController
        // using 80% of height as the maximum avoids an ugly trailing animation
        let offset = -min(distance, height * 0.8) / 2
        scanner?.setOverlayOffset(offset)
    }
}

// MARK: - appearance
extension ScannerDrawerViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutBar?.setCustomAppearance(appearance)
        self.customAppearance = appearance
    }
}

extension ScannerDrawerViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        self.shoppingCartDelegate?.track(event)
    }
}
