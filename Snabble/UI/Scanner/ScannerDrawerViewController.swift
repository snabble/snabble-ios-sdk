//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

final class ScannerDrawerViewController: UIViewController {
    private var shoppingList: ShoppingList?
    private var shoppingListTableVC: ScannerShoppingListViewController

    private let shoppingCart: ShoppingCart
    private var shoppingCartVC: ShoppingCartTableViewController

    private let projectId: Identifier<Project>

    private var customAppearance: CustomAppearance?

    private weak var cartDelegate: ShoppingCartDelegate?

    public weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate? {
        didSet {
            self.checkoutBar?.paymentMethodNavigationDelegate = self.paymentMethodNavigationDelegate
        }
    }

    private let minDrawerHeight: CGFloat = 50
    private let totalsHeight: CGFloat = 88
    private let segmentedControlHeight: CGFloat = 50

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

    init(_ projectId: Identifier<Project>, shoppingCart: ShoppingCart, cartDelegate: ShoppingCartDelegate) {
        self.projectId = projectId
        self.shoppingCart = shoppingCart
        self.cartDelegate = cartDelegate

        self.shoppingListTableVC = ScannerShoppingListViewController(delegate: cartDelegate)
        self.shoppingCartVC = ShoppingCartTableViewController(shoppingCart, cartDelegate: cartDelegate)

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

        segmentedControl.setTitle("Snabble.ShoppingList.title".localized(), forSegmentAt: 0)
        segmentedControl.setTitle("Snabble.ShoppingCart.title".localized(), forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        if #available(iOS 13.0, *) {
            let appearance = SnabbleUI.appearance
            segmentedControl.selectedSegmentTintColor = appearance.accentColor
            segmentedControl.setTitleTextAttributes([.foregroundColor: appearance.accentColor.contrast], for: .selected)
        }

        let checkoutBar = CheckoutBar(self, shoppingCart, cartDelegate: cartDelegate)
        self.checkoutWrapper.addSubview(checkoutBar)
        NSLayoutConstraint.activate([
            checkoutWrapper.topAnchor.constraint(equalTo: checkoutBar.topAnchor),
            checkoutWrapper.rightAnchor.constraint(equalTo: checkoutBar.rightAnchor),
            checkoutWrapper.bottomAnchor.constraint(equalTo: checkoutBar.bottomAnchor),
            checkoutWrapper.leftAnchor.constraint(equalTo: checkoutBar.leftAnchor)
        ])
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupBlurEffect()
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

        let noList = shoppingList == nil
        segmentedControl?.isHidden = noList
        innerSpacer?.isHidden = noList
        if noList {
            selectSegment(1)
        } else {
            selectSegment(0)
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
}

// MARK: - pulley
extension ScannerDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .open]
    }

    public func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let heightForTotals = shoppingCart.numberOfProducts == 0 ? 0 : self.totalsHeight
        let heightForSegmentedControl = shoppingList == nil ? 0 : self.segmentedControlHeight
        return self.minDrawerHeight + heightForSegmentedControl + heightForTotals
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
        self.cartDelegate?.track(event)
    }
}
