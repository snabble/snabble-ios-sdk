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
    private var shoppingCartVC: ShoppingCartViewController

    private let projectId: Identifier<Project>

    private var customAppearance: CustomAppearance?

    private weak var delegate: ShoppingCartDelegate?

    private var previousPosition = PulleyPosition.closed

    @IBOutlet private var handleContainer: UIView!
    @IBOutlet private var handle: UIView!

    @IBOutlet private var itemCountLabel: UILabel!
    @IBOutlet private var totalPriceLabel: UILabel!

    @IBOutlet private var methodSelectionView: UIView!
    @IBOutlet private var methodIcon: UIImageView!
    @IBOutlet private var methodSpinner: UIActivityIndicatorView!
    @IBOutlet private var checkoutButton: UIButton!

    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var innerSpacer: UIView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var separatorHeight: NSLayoutConstraint!

    init(_ projectId: Identifier<Project>, shoppingCart: ShoppingCart, delegate: ShoppingCartDelegate) {
        self.projectId = projectId
        self.shoppingCart = shoppingCart
        self.delegate = delegate

        self.shoppingListTableVC = ScannerShoppingListViewController(delegate: delegate)
        self.shoppingCartVC = ShoppingCartViewController(shoppingCart, delegate: delegate)

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        handle.layer.cornerRadius = 2
        handle.layer.masksToBounds = true
        handle.backgroundColor = .systemGray
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

        self.checkoutButton.setTitle("Snabble.Shoppingcart.buyProducts.now".localized(), for: .normal)
        self.checkoutButton.makeSnabbleButton()

        self.methodSelectionView.layer.masksToBounds = true
        self.methodSelectionView.layer.cornerRadius = 8
        self.methodSelectionView.layer.borderColor = UIColor.lightGray.cgColor
        self.methodSelectionView.layer.borderWidth = 1 / UIScreen.main.scale

        self.totalPriceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)

        self.separatorHeight.constant = 1 / UIScreen.main.scale

        self.switchTo(shoppingListTableVC, in: contentView, duration: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let custom = self.customAppearance {
            self.checkoutButton.setCustomAppearance(custom)
        }

        self.updateShoppingLists()
    }

    @objc private func handleTapped(_ gesture: UITapGestureRecognizer) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }

    @objc private func tabChanged(_ control: UISegmentedControl) {
        let activeVC: UIViewController
        if control.selectedSegmentIndex == 0 {
            activeVC = self.shoppingListTableVC
        } else {
            activeVC = self.shoppingCartVC
        }

        self.switchTo(activeVC, in: contentView)
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
            switchTo(shoppingCartVC, in: contentView)
            segmentedControl.selectedSegmentIndex = 1
        }

        pulleyViewController?.setNeedsSupportedDrawerPositionsUpdate()
    }

    func markScannedProduct(_ product: Product) {
        shoppingListTableVC.markScannedProduct(product)
    }
}

// MARK: - pulley
extension ScannerDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return shoppingList == nil ? 128 : 168
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
        shoppingListTableVC.tableView.contentInset = insets
        shoppingListTableVC.tableView.scrollIndicatorInsets = insets

        let scanner = self.pulleyViewController?.primaryContentViewController as? ScanningViewController
        // using 80% of height as the maximum avoids an ugly trailing animation
        let offset = -min(distance, height * 0.8) / 2
        scanner?.setOverlayOffset(offset)
    }
}

// MARK: - appearance
extension ScannerDrawerViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutButton?.setCustomAppearance(appearance)
        self.customAppearance = appearance
    }
}
