//
//  BarcodeEntryViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

public final class BarcodeEntryViewController: UIViewController {
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var bottomMargin: NSLayoutConstraint?

    private weak var productProvider: ProductProviding?
    private let shopId: Identifier<Shop>

    private let completion: ((String, ScanFormat?, String?) -> Void)

    private var filteredProducts = [Product]()
    private var searchText = ""
    private var keyboardObserver: KeyboardObserver?
    private var emptyState: EmptyStateView?
    private var showSku = false

    public weak var analyticsDelegate: AnalyticsDelegate?

    public init(_ productProvider: ProductProviding,
                _ shopId: Identifier<Shop>,
                showSku: Bool = false,
                completion: @escaping @Sendable (String, ScanFormat?, String?) -> Void
    ) {
        self.productProvider = productProvider
        self.shopId = shopId
        self.completion = completion
        self.showSku = showSku

        super.init(nibName: nil, bundle: nil)

        self.title = Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.keyboardType = .numberPad
        view.addSubview(searchBar)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                .usingVariable(&bottomMargin)
        ])

        self.emptyState = BarcodeEntryEmptyStateView({ [weak self] _ in self?.addEnteredCode() })
        self.emptyState?.addTo(self.tableView)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.register(BarcodeEntryTableCell.self, forCellReuseIdentifier: "barcodeCell")

        self.searchBar.placeholder = Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode")

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.view.backgroundColor = .systemBackground
        self.tableView.backgroundColor = .clear
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.becomeFirstResponder()

        self.analyticsDelegate?.track(.viewBarcodeEntry)
    }

    private func addEnteredCode() {
        self.addCode(self.searchText, nil)
    }

    private func addCode(_ code: String, _ template: String?) {
        let block = {
            self.analyticsDelegate?.track(.barcodeSelected(code))
            self.completion(code, nil, template)
        }

        // popViewController has no completion handler, so we roll our own
        CATransaction.begin()
        CATransaction.setCompletionBlock(block)
        _ = self.navigationController?.popViewController(animated: false)
        CATransaction.commit()
    }
}

extension BarcodeEntryViewController: UISearchBarDelegate {
    // MARK: - search bar
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            let products = self.productProvider?.productsBy(prefix: searchText,
                                                            filterDeposits: true,
                                                            templates: SnabbleCI.project.searchableTemplates,
                                                            shopId: self.shopId)
            self.filteredProducts = removeDuplicates(products ?? []).sorted { prod1, prod2 in
                let code1 = prod1.codes.filter { $0.code.hasPrefix(searchText) }.first ?? prod1.codes.first!
                let code2 = prod2.codes.filter { $0.code.hasPrefix(searchText) }.first ?? prod2.codes.first!
                return code1.code < code2.code
            }
        } else {
            self.filteredProducts.removeAll()
        }
        self.searchText = searchText
        self.tableView.reloadData()
    }

    private func removeDuplicates(_ products: [Product]) -> [Product] {
        var skusAdded = [String: Bool]()

        return products.filter {
            skusAdded.updateValue(true, forKey: $0.sku) == nil
        }
    }
}

extension BarcodeEntryViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = filteredProducts.count
        self.emptyState?.isHidden = rows > 0
        self.emptyState?.button1.isHidden = true
        if !self.searchText.isEmpty {
            let title = Asset.localizedString(forKey: "Snabble.Scanner.addCodeAsIs", arguments: self.searchText)
            self.emptyState?.button1.setTitle(title, for: .normal)
            self.emptyState?.button1.isHidden = false
        }
        return rows
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "barcodeCell", for: indexPath)

        let product = self.filteredProducts[indexPath.row]
        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        let str = NSMutableAttributedString(string: codeEntry.code)
        if codeEntry.code.hasPrefix(self.searchText) {
            let boldFont: UIFont = .preferredFont(forTextStyle: .body, weight: .semibold)
            str.addAttributes([NSAttributedString.Key.font: boldFont], range: NSRange(location: 0, length: self.searchText.count))
        }
        cell.textLabel?.attributedText = str

        cell.detailTextLabel?.text = product.name
        if self.showSku {
            cell.detailTextLabel?.text = "\(product.name) (\(product.sku))"
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let product = self.filteredProducts[indexPath.row]

        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        self.addCode(codeEntry.code, codeEntry.template)
    }
}

extension BarcodeEntryViewController: KeyboardHandling {
    public func keyboardWillShow(_ info: KeyboardInfo) {
        // compensate for the opaque tab bar
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 0
        let keyboardHeight = info.keyboardHeight - tabBarHeight

        self.bottomMargin?.constant = -keyboardHeight
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        self.bottomMargin?.constant = 0
    }
}

private class BarcodeEntryTableCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
