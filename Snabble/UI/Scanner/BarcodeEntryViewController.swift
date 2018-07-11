//
//  BarcodeEntryViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class BarcodeEntryViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!

    private weak var productProvider: ProductProvider!

    private var completion: ((String)->Void)!

    private var filteredProducts = [Product]()
    private var searchText = ""
    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: AnalyticsDelegate!
    private var emptyState: EmptyStateView!

    init(_ productProvider: ProductProvider, delegate: AnalyticsDelegate, completion: @escaping (String)->() ) {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.productProvider = productProvider
        self.completion = completion
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emptyState = BarcodeEntryEmptyStateView(self.addEnteredCode)
        self.emptyState.addTo(self.tableView)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.searchBar.placeholder = "Snabble.Scanner.enterBarcode".localized()
        
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        let primaryBackgroundColor = SnabbleAppearance.shared.config.primaryBackgroundColor
        self.view.backgroundColor = primaryBackgroundColor
        self.tableView.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.becomeFirstResponder()

        self.delegate.track(.viewBarcodeEntry)
    }

    // MARK: - search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filteredProducts = self.productProvider.productsByScannableCodePrefix(searchText, filterDeposits: true)

        self.searchText = searchText
        self.tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let _ = self.navigationController?.popViewController(animated: true)
    }

    // MARK: - table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = filteredProducts.count
        self.emptyState.isHidden = rows > 0
        self.emptyState.button.isHidden = true
        if self.searchText.count > 0 {
            let title = String(format: "Snabble.Scanner.addCodeAsIs".localized(), self.searchText)
            self.emptyState.button.setTitle(title, for: .normal)
            self.emptyState.button.isHidden = false
        }
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "barcodeCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        let product = self.filteredProducts[indexPath.row]
        let matchingCode = product.scannableCodes.filter { $0.hasPrefix(self.searchText) }.first ?? product.scannableCodes.first!
        
        let str = NSMutableAttributedString(string: matchingCode)
        let boldFont = UIFont.systemFont(ofSize: cell.textLabel?.font.pointSize ?? 0, weight: .medium)
        str.addAttributes([NSAttributedStringKey.font : boldFont], range: NSMakeRange(0, self.searchText.count))
        cell.textLabel?.attributedText = str

        cell.detailTextLabel?.text = product.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = self.filteredProducts[indexPath.row]

        let matchingCode = product.scannableCodes.filter { $0.hasPrefix(self.searchText) }.first ?? product.scannableCodes.first!
        self.addCode(matchingCode)
    }

    func addEnteredCode() {
        self.addCode(self.searchText)
    }

    func addCode(_ code: String) {
        // popViewController has no completion handler, so we roll our own
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.delegate.track(.barcodeSelected(code))
            self.completion?(code)
        }

        let _ = self.navigationController?.popViewController(animated: false)
        CATransaction.commit()
    }
    
}

extension BarcodeEntryViewController: KeyboardHandling {

    func keyboardWillShow(_ info: KeyboardInfo) {
        // compensate for the opaque tab bar
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 0
        let keyboardHeight = info.keyboardHeight - tabBarHeight

        self.bottomMargin.constant = keyboardHeight
    }

    func keyboardWillHide(_ info: KeyboardInfo) {
        // not used
    }

}
