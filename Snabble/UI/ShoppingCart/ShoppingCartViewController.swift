//
//  ShoppingCartViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

/// a protocol that users of `ShoppingCartViewController` must implement
public protocol ShoppingCartDelegate: AnalyticsDelegate, MessageDelegate {
    /// called when the user wants to initiate payment.
    /// Implementations should usually create a `PaymentProcess` instance and invoke its `start` method
    func gotoPayment(_ info: SignedCheckoutInfo, _ cart: ShoppingCart)

    /// called when the "Scan Products" button in the cart's empty state is tapped
    func gotoScanner()

    /// called when an error occurred
    ///
    /// - Parameter error: if not nil, the ApiError from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handleCheckoutError(_ error: ApiError?) -> Bool
}
 
public class ShoppingCartViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var checkoutButton: UIButton!

    private var editButton: UIBarButtonItem!
    private var trashButton: UIBarButtonItem!

    private var emptyState: ShoppingCartEmptyStateView!

    private let itemCellIdentifier = "itemCell"
    public var shoppingCart: ShoppingCart! {
        didSet {
            self.tableView?.reloadData()
            self.updateTotals()
        }
    }

    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: ShoppingCartDelegate!
    
    public init(_ cart: ShoppingCart, delegate: ShoppingCartDelegate) {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.shoppingCart = cart
        self.delegate = delegate

        self.title = "Snabble.ShoppingCart.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("icon-cart")

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.updateShoppingCart(_:)), name: .snabbleCartUpdated, object: nil)

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.updateTotals()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let primaryBackgroundColor = SnabbleAppearance.shared.config.primaryBackgroundColor
        self.view.backgroundColor = primaryBackgroundColor

        self.emptyState = ShoppingCartEmptyStateView(self.showScanner)
        self.emptyState.addTo(self.view)

        self.tableView.register(UINib(nibName: "ShoppingCartTableCell", bundle: Snabble.bundle), forCellReuseIdentifier: self.itemCellIdentifier)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 88

        self.editButton = UIBarButtonItem(title: "Snabble.Edit".localized(), style: .plain, target: self, action: #selector(self.toggleEditingMode(_:)))
        self.editButton.possibleTitles = Set(["Snabble.Edit".localized(), "Snabble.Done".localized()])

        self.trashButton = UIBarButtonItem(image: UIImage.fromBundle("icon-trash"), style: .plain, target: self, action: #selector(self.trashButtonTapped(_:)))

        self.tableBottomMargin.constant = 0

        self.checkoutButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        self.checkoutButton.backgroundColor = SnabbleAppearance.shared.config.primaryColor
        self.checkoutButton.tintColor = SnabbleAppearance.shared.config.secondaryColor
        self.checkoutButton.makeRoundedButton()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewShoppingCart)

        // WTF? without this code, the button text sometimes appears as .textColor :(
        self.checkoutButton.tintColor = SnabbleAppearance.shared.config.secondaryColor
        self.checkoutButton.titleLabel?.textColor = SnabbleAppearance.shared.config.secondaryColor
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // turn off table editing, and re-enable everything that is disabled while editing
        self.isEditing = false
        self.editButton.title = "Snabble.Edit".localized()
        self.tableView.isEditing = false
    }

    private func setEditButton() {
        let navItem = self.navigationItem
        let items = self.shoppingCart.numberOfItems()
        navItem.rightBarButtonItem = items == 0 ? nil : self.editButton
    }
    
    private func setDeleteButton() {
        let navItem = self.navigationItem
        navItem.leftBarButtonItem = self.isEditing ? self.trashButton : nil
    }

    // MARK: notification handlers
    @objc private func updateShoppingCart(_ notification: Notification) {
        self.updateTotals()
    }

    @objc private func toggleEditingMode(_ sender: UIBarButtonItem) {
        self.setEditingMode(!self.isEditing)
    }
    
    private func setEditingMode(_ editing: Bool) {
        self.tableView.reloadData()
        
        self.isEditing = editing
        self.tableView.isEditing = editing
        
        self.editButton.title = editing ? "Snabble.Done".localized() : "Snabble.Edit".localized()
        self.setDeleteButton()
        
        self.tableView.reloadData()
        self.tableView.setNeedsLayout()
    }

    @objc private func trashButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Snabble.Shoppingcart.removeItems".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            self.delegate.track(.deletedEntireCart)
            self.shoppingCart.removeAll()
            self.updateView()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    private func updateView() {
        self.tableView.reloadData()
        
        self.setEditButton()
        self.setDeleteButton()
        
        let items = self.shoppingCart.numberOfItems()
        if items == 0 {
            self.setEditingMode(false)
        }
        
        self.updateTotals()
    }

    @IBAction func checkoutTapped(_ sender: UIButton) {
        self.startCheckout()
    }

    public func startCheckout() {
        let button = self.checkoutButton!

        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.startAnimating()
        button.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        button.isEnabled = false

        self.shoppingCart.createCheckoutInfo() { info, error in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            button.isEnabled = true
            if let info = info {
                self.delegate.gotoPayment(info, self.shoppingCart)
            } else {
                let handled = self.delegate.handleCheckoutError(error)
                if !handled {
                    self.delegate.showInfoMessage("Snabble.Payment.errorStarting".localized())
                }
            }
        }
    }

    func showScanner() {
        self.delegate.gotoScanner()
    }
}

extension ShoppingCartViewController: ShoppingCartTableDelegate {

    func confirmDeletion(at row: Int) {
        guard let product = self.shoppingCart.product(at: row) else {
            return
        }
        let msg = String(format: "Snabble.Shoppingcart.removeItem".localized(), product.name)
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            self.deleteRow(row)
        })

        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel) { action in
            self.shoppingCart.setQuantity(1, at: row)
            let indexPath = IndexPath(row: row, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        })

        self.present(alert, animated: true)
    }

    func updateTotals() {
        let total = self.shoppingCart.totalPrice
        let formattedTotal = Price.format(self.cart.totalPrice)
        if total == 0 {
            self.tabBarItem.title = "Snabble.ShoppingCart.title".localized()
        } else {
            self.tabBarItem.title = formattedTotal
        }

        let count = self.shoppingCart.numberOfItems()

        let fmt = count == 1 ? "Snabble.Shoppingcart.buyProducts.one" : "Snabble.Shoppingcart.buyProducts"
        let title = String(format: fmt.localized(), count, formattedTotal)
        UIView.performWithoutAnimation {
            self.checkoutButton?.setTitle(title, for: .normal)
            self.checkoutButton?.layoutIfNeeded()
        }

        self.checkoutButton?.isHidden = count == 0
    }

    var cart: ShoppingCart {
        return self.shoppingCart
    }
}

extension ShoppingCartViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: table view data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = self.shoppingCart.count
        self.emptyState.isHidden = rows > 0
        return rows
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.itemCellIdentifier, for: indexPath) as! ShoppingCartTableCell

        let item = self.shoppingCart.at(indexPath.row)
        cell.setCartItem(item, row: indexPath.row, delegate: self)

        return cell
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(indexPath.row)
        }
    }

    // MARK: table view delegate

    // call tableView.deleteRowsAtIndexPaths() inside a CATransaction block so that we can reload the tableview afterwards
    func deleteRow(_ row: Int) {
        if let product = self.shoppingCart.product(at: row) {
            self.delegate.track(.deletedFromCart(product.sku))
        }

        self.shoppingCart.remove(at: row)
        let indexPath = IndexPath(row: row, section: 0)
        CATransaction.begin()
        self.tableView.deleteRows(at: [indexPath], with: .none)

        CATransaction.setCompletionBlock {
            self.updateView()
        }
        
        CATransaction.commit()
    }

    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Snabble.remove".localized()
    }
}

// MARK: keyboard show/hide
extension ShoppingCartViewController: KeyboardHandling {

    public func keyboardWillShow(_ info: KeyboardInfo) {
        guard self.view.window != nil else {
            return
        }

        // compensate for the opaque tab bar
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 0
        self.tableBottomMargin.constant = info.keyboardHeight - tabBarHeight
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        guard self.view.window != nil else {
            return
        }

        self.tableBottomMargin.constant = 0
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}

