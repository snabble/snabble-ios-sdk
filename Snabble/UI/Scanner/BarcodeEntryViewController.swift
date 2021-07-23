//
//  BarcodeEntryViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class BarcodeEntryViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var bottomMargin: NSLayoutConstraint!

    private weak var productProvider: ProductProvider!
    private let shopId: Identifier<Shop>

    private let completion: ((String, ScanFormat?, String?) -> Void)

    private var filteredProducts = [Product]()
    private var searchText = ""
    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: AnalyticsDelegate!
    private var emptyState: EmptyStateView!
    private var showSku = false

    public init(_ productProvider: ProductProvider,
                _ shopId: Identifier<Shop>,
                delegate: AnalyticsDelegate,
                showSku: Bool = false,
                completion: @escaping (String, ScanFormat?, String?) -> Void
    ) {
        self.productProvider = productProvider
        self.shopId = shopId
        self.completion = completion
        self.delegate = delegate
        self.showSku = showSku

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Scanner.enterBarcode".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.emptyState = BarcodeEntryEmptyStateView({ [weak self] _ in self?.addEnteredCode() })
        self.emptyState.addTo(self.tableView)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.searchBar.placeholder = "Snabble.Scanner.enterBarcode".localized()

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.view.backgroundColor = .systemBackground
        self.tableView.backgroundColor = .clear
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.becomeFirstResponder()

        self.delegate.track(.viewBarcodeEntry)
    }

    private func addEnteredCode() {
        self.addCode(self.searchText, nil)
    }

    private func addCode(_ code: String, _ template: String?) {
        let block = {
            self.delegate.track(.barcodeSelected(code))
            self.completion(code, nil, template)
        }

        if SnabbleUI.implicitNavigation {
            // popViewController has no completion handler, so we roll our own
            CATransaction.begin()
            CATransaction.setCompletionBlock(block)
            _ = self.navigationController?.popViewController(animated: false)
            CATransaction.commit()
        } else {
            block()
        }
    }
}

extension BarcodeEntryViewController: UISearchBarDelegate {
    // MARK: - search bar
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            let products = self.productProvider.productsByScannableCodePrefix(searchText,
                                                                              filterDeposits: true,
                                                                              templates: SnabbleUI.project.searchableTemplates,
                                                                              shopId: self.shopId)
            self.filteredProducts = removeDuplicates(products).sorted { prod1, prod2 in
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
        self.emptyState.isHidden = rows > 0
        self.emptyState.button1.isHidden = true
        if !self.searchText.isEmpty {
            let title = String(format: "Snabble.Scanner.addCodeAsIs".localized(), self.searchText)
            self.emptyState.button1.setTitle(title, for: .normal)
            self.emptyState.button1.isHidden = false
        }
        return rows
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "barcodeCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.selectionStyle = .none
            return cell
        }()

        let product = self.filteredProducts[indexPath.row]
        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        let str = NSMutableAttributedString(string: codeEntry.code)
        if codeEntry.code.hasPrefix(self.searchText) {
            let boldFont = UIFont.systemFont(ofSize: cell.textLabel?.font.pointSize ?? 0, weight: .medium)
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

        self.bottomMargin.constant = keyboardHeight
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        // not used
    }
}
