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
        self.shoppingCartVC = ShoppingCartTableViewController(shoppingCart)

        super.init(nibName: nil, bundle: nil)

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.translatesAutoresizingMaskIntoConstraints = false

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

        let wrapperStackView = UIStackView()
        wrapperStackView.translatesAutoresizingMaskIntoConstraints = false
        wrapperStackView.axis = .vertical
        wrapperStackView.distribution = .fill
        wrapperStackView.alignment = .fill
        wrapperStackView.spacing = 0

        let checkoutBar = CheckoutBar(self, shoppingCart)
        checkoutBar.translatesAutoresizingMaskIntoConstraints = false

        let innerSpacer = UIView()
        innerSpacer.translatesAutoresizingMaskIntoConstraints = false

        let segmentedControl = UISegmentedControl(items: [Asset.localizedString(forKey: "Snabble.ShoppingList.title"), Asset.localizedString(forKey: "Snabble.ShoppingCart.title")])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)

        let separatorSpacer = UIView()
        separatorSpacer.translatesAutoresizingMaskIntoConstraints = false

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

        wrapperStackView.addArrangedSubview(checkoutBar)
        wrapperStackView.addArrangedSubview(innerSpacer)
        wrapperStackView.addArrangedSubview(segmentedControl)
        wrapperStackView.addArrangedSubview(separatorSpacer)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            handleView.widthAnchor.constraint(equalToConstant: 35),
            handleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            handleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            handleView.heightAnchor.constraint(equalToConstant: 5).usingPriority(.defaultHigh + 2),

            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).usingPriority(.defaultHigh + 1),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).usingPriority(.defaultHigh + 1),
            wrapperStackView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 4).usingPriority(.defaultHigh + 1),

            checkoutBar.leadingAnchor.constraint(equalTo: wrapperStackView.leadingAnchor).usingPriority(.defaultHigh + 1),
            checkoutBar.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor).usingPriority(.defaultHigh + 1),

            innerSpacer.heightAnchor.constraint(equalToConstant: innerSpacerHeight).usingPriority(.defaultHigh),

            segmentedControl.heightAnchor.constraint(equalToConstant: segmentedControlHeight).usingPriority(.defaultHigh + 1),

            separatorSpacer.heightAnchor.constraint(equalToConstant: separatorSpacerHeight).usingPriority(.defaultHigh),

            separator.topAnchor.constraint(equalTo: wrapperStackView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).usingPriority(.defaultHigh),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bottomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            bottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        self.view = contentView
        self.effectView = effectView
        self.checkoutBar = checkoutBar
        self.segmentedControl = segmentedControl
        self.innerSpacer = innerSpacer
        self.bottomView = bottomView

        if #available(iOS 15, *) {
            self.view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up appearance for translucency effect
        view.backgroundColor = .clear
        self.shoppingListTableVC.view.backgroundColor = .clear
        self.shoppingCartVC.view.backgroundColor = .clear
        setupBlurEffect()

        checkoutBar?.shoppingCartDelegate = shoppingCartDelegate

        self.bottomViewSwitchTo(shoppingListTableVC, duration: 0)

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
        if let customAppearance = self.customAppearance {
            self.checkoutBar?.setCustomAppearance(customAppearance)
        }
    }

    private func setupBlurEffect() {
        self.effectView?.effect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .light ? .extraLight : .dark)
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

        let heightForSegmentedControl = shoppingList == nil ? 0 : segmentedControlHeight + separatorSpacerHeight
        return minDrawerHeight + heightForSegmentedControl + totalsHeight + heightForItems
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
