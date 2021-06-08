//
//  ScannerShoppingListViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

// child VC of the ScannerDrawerViewController: display the current shopping list

final class ScannerShoppingListViewController: UITableViewController {
    private var shoppingList: ShoppingList?
    private weak var delegate: AnalyticsDelegate?

    var insets: UIEdgeInsets = .zero {
        didSet {
            tableView?.contentInset = insets
            tableView?.scrollIndicatorInsets = insets
        }
    }

    init(delegate: AnalyticsDelegate?) {
        self.delegate = delegate
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        let nib = UINib(nibName: "ShoppingListCell", bundle: SnabbleBundle.main)
        tableView.register(nib, forCellReuseIdentifier: "shoppingListCell")
        // compensate for the 20pt overshoot from Pulley
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    func reload(_ shoppingList: ShoppingList?) {
        self.shoppingList = shoppingList
        tableView.reloadData()
    }

    func markScannedProduct(_ product: Product) {
        guard
            let list = shoppingList,
            let index = list.findProductIndex(sku: product.sku)
        else {
            return
        }

        let checked = list.itemAt(index).checked
        if !checked {
            delegate?.track(.itemMarkedDoneScanner)
            _ = list.toggleChecked(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}

// MARK: - TableView
extension ScannerShoppingListViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingList?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as! ShoppingListCell

        let item = shoppingList!.itemAt(indexPath.row)
        cell.setListItem(item)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let checked = shoppingList!.toggleChecked(at: indexPath.row)
        delegate?.track(checked ? .itemMarkedDone : .itemMarkedTodo)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
