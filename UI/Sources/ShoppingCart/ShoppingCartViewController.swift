//
//  ShoppingCartViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

// standalone shopping cart
// this embeds the ShoppingCartTableViewController as a child VC, plus a CheckoutBar

public final class ShoppingCartViewController: UIViewController {
    private let shoppingCartTableVC: ShoppingCartTableViewController
    private let bottomWrapper = UIView()
    private var checkoutBar: CheckoutBar!

    private var customAppearance: CustomAppearance?
    private var emptyState: ShoppingCartEmptyStateView!
    private let shoppingCart: ShoppingCart
    private weak var restoreTimer: Timer?
    private var trashButton: UIBarButtonItem!

    public weak var shoppingCartDelegate: ShoppingCartDelegate? {
        didSet {
            shoppingCartTableVC.shoppingCartDelegate = shoppingCartDelegate
            checkoutBar.shoppingCartDelegate = shoppingCartDelegate
        }
    }

    // WARNING!!!
    public init(_ shoppingCart: ShoppingCart) {
        self.shoppingCart = shoppingCart
        self.shoppingCartTableVC = ShoppingCartTableViewController(shoppingCart)

        super.init(nibName: nil, bundle: nil)

        self.title = Asset.localizedString(forKey: "Snabble.ShoppingCart.title")
        let cartEmpty = shoppingCart.numberOfProducts == 0
        self.tabBarItem.image = cartEmpty ? Asset.image(named: "SnabbleSDK/icon-cart-inactive-empty") : Asset.image(named: "SnabbleSDK/icon-cart-inactive-full")
        self.tabBarItem.selectedImage = Asset.image(named: "SnabbleSDK/icon-cart-active")

        self.checkoutBar = CheckoutBar(self, shoppingCart)

        self.emptyState = ShoppingCartEmptyStateView { [weak self] button in
            self?.emptyStateButtonTapped(button)
        }
        self.emptyState.addTo(self.view)

        SnabbleCI.registerForAppearanceChange(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15, *) {
            self.view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        self.shoppingCart.delegate = self

        self.trashButton = UIBarButtonItem(image: Asset.image(named: "trash"), style: .plain, target: self, action: #selector(self.trashButtonTapped(_:)))

        self.view.backgroundColor = .systemBackground

        let cartView = shoppingCartTableVC.view!
        cartView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(cartView)

        bottomWrapper.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomWrapper)

        checkoutBar.translatesAutoresizingMaskIntoConstraints = false
        bottomWrapper.addSubview(checkoutBar)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator
        bottomWrapper.addSubview(separator)

        NSLayoutConstraint.activate([
            cartView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cartView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cartView.topAnchor.constraint(equalTo: view.topAnchor),
            cartView.bottomAnchor.constraint(equalTo: bottomWrapper.topAnchor),

            bottomWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomWrapper.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            separator.leadingAnchor.constraint(equalTo: bottomWrapper.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bottomWrapper.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: bottomWrapper.topAnchor),

            checkoutBar.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            checkoutBar.leadingAnchor.constraint(equalTo: bottomWrapper.leadingAnchor, constant: 16),
            checkoutBar.trailingAnchor.constraint(equalTo: bottomWrapper.trailingAnchor, constant: -16),
            checkoutBar.bottomAnchor.constraint(equalTo: bottomWrapper.bottomAnchor, constant: -16)
        ])

        self.addChild(shoppingCartTableVC)
        shoppingCartTableVC.didMove(toParent: self)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let custom = self.customAppearance {
            checkoutBar?.setCustomAppearance(custom)
        }

        checkoutBar?.updateSelectionVisibility()
        updateView()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // turn off table editing, and re-enable everything that is disabled while editing
        self.isEditing = false
        self.setEditing(false, animated: false)
        self.shoppingCartTableVC.isEditing = false
    }

    private func setEditButton() {
        let navItem = self.navigationItem
        let items = self.shoppingCartTableVC.itemCount
        navItem.rightBarButtonItem = items == 0 ? nil : self.editButtonItem
    }

    private func setDeleteButton() {
        let navItem = self.navigationItem
        navItem.leftBarButtonItem = self.isEditing ? self.trashButton : nil
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.shoppingCartTableVC.setEditing(editing, animated: animated)

        self.setDeleteButton()
    }

    @objc private func trashButtonTapped(_ sender: UIBarButtonItem) {
        self.showDeleteCartAlert()
    }

    @objc private func shoppingCartUpdated(_ notification: Notification) {
        self.updateView()
    }

    private func updateView() {
        let numProducts = self.shoppingCart.numberOfProducts

        self.tabBarItem.image = numProducts == 0 ? Asset.image(named: "SnabbleSDK/icon-cart-inactive-empty") : Asset.image(named: "SnabbleSDK/icon-cart-inactive-full")

        setEditButton()
        setDeleteButton()

        self.emptyState.isHidden = numProducts > 0
        self.bottomWrapper.isHidden = numProducts == 0

        checkoutBar?.updateTotals()
    }

    func updateTotals() {
        checkoutBar?.updateTotals()
    }
}

// MARK: - empty state
extension ShoppingCartViewController {
    private func configureEmptyState() {
        if self.shoppingCart.items.isEmpty == true && self.shoppingCart.backupAvailable {
            self.emptyState.button1.setTitle(Asset.localizedString(forKey: "Snabble.Shoppingcart.EmptyState.restartButtonTitle"), for: .normal)
            self.emptyState.button2.isHidden = false
            let restoreInterval: TimeInterval = 5 * 60
            self.restoreTimer?.invalidate()
            self.restoreTimer = Timer.scheduledTimer(withTimeInterval: restoreInterval, repeats: false) { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.emptyState.button1.setTitle(Asset.localizedString(forKey: "Snabble.Shoppingcart.EmptyState.buttonTitle"), for: .normal)
                    self?.emptyState.button2.isHidden = true
                }
            }
        } else {
            self.emptyState.button2.isHidden = true
            self.restoreTimer?.invalidate()
        }
    }

    private func emptyStateButtonTapped(_ button: UIButton) {
        switch button.tag {
        case 0: self.showScanner()
        case 1: self.restoreCart()
        default: ()
        }
    }

    private func showScanner() {
        self.shoppingCartDelegate?.gotoScanner()
    }

    private func restoreCart() {
        self.shoppingCart.restoreCart()
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.shoppingCartTableVC.updateView()
    }

    func showDeleteCartAlert() {
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Shoppingcart.removeItems"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            self.deleteCart()
            self.setDeleteButton()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    public func deleteCart() {
        self.shoppingCartTableVC.deleteCart()
    }
}

// MARK: - appearance
extension ShoppingCartViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance
        self.shoppingCartTableVC.setCustomAppearance(appearance)

        SnabbleCI.getAsset(.storeLogoSmall) { img in
            if let image = img ?? appearance.titleIcon {
                let imgView = UIImageView(image: image)
                self.navigationItem.titleView = imgView
            }
        }
    }
}

extension ShoppingCartViewController: AnalyticsDelegate {
    public func track(_ event: AnalyticsEvent) {
        shoppingCartDelegate?.track(event)
    }
}

extension ShoppingCartViewController: InternalShoppingCartDelegate {
    public func shoppingCart(_ shoppingCart: ShoppingCart, didChangeCustomerCard customerCard: String?) {
        updateTotals()
    }

    public func shoppingCart(_ shoppingCart: ShoppingCart, violationsDetected violations: [CheckoutInfo.Violation]) {
        let alertController = UIAlertController(
            title: Asset.localizedString(forKey: "Snabble.Violations.title"),
            message: violations.message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: Asset.localizedString(forKey: "Snabble.ok"),
            style: .default) { _ in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
