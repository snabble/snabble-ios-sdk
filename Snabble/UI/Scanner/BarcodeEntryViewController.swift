//
//  BarcodeEntryViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

final public class BarcodeEntryViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!

    private weak var productProvider: ProductProvider!

    private var completion: ((String, String?)->Void)!

    private var filteredProducts = [Product]()
    private var searchText = ""
    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: AnalyticsDelegate!
    private var emptyState: EmptyStateView!

    public init(_ productProvider: ProductProvider, delegate: AnalyticsDelegate, completion: @escaping (String, String?)->() ) {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.productProvider = productProvider
        self.completion = completion
        self.delegate = delegate

        self.title = "Snabble.Scanner.enterBarcode".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.emptyState = BarcodeEntryEmptyStateView( { [weak self] in self?.addEnteredCode() } )
        self.emptyState.addTo(self.tableView)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.searchBar.placeholder = "Snabble.Scanner.enterBarcode".localized()
        
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        let primaryBackgroundColor = SnabbleUI.appearance.primaryBackgroundColor
        self.view.backgroundColor = primaryBackgroundColor
        self.tableView.backgroundColor = .clear
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.becomeFirstResponder()

        self.delegate.track(.viewBarcodeEntry)
    }

    // MARK: - search bar
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            let products = self.productProvider.productsByScannableCodePrefix(searchText, filterDeposits: true, templates: SnabbleUI.project.searchableTemplates)
            self.filteredProducts = products.sorted { p1, p2 in
                let c1 = p1.codes.filter { $0.code.hasPrefix(searchText) }.first ?? p1.codes.first!
                let c2 = p2.codes.filter { $0.code.hasPrefix(searchText) }.first ?? p2.codes.first!
                return c1.code < c2.code
            }
        } else {
            self.filteredProducts.removeAll()
        }
        self.searchText = searchText
        self.tableView.reloadData()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let _ = self.navigationController?.popViewController(animated: true)
    }

    // MARK: - table view
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "barcodeCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        let product = self.filteredProducts[indexPath.row]
        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        let str = NSMutableAttributedString(string: codeEntry.code)
        let boldFont = UIFont.systemFont(ofSize: cell.textLabel?.font.pointSize ?? 0, weight: .medium)
        str.addAttributes([NSAttributedString.Key.font : boldFont], range: NSMakeRange(0, self.searchText.count))
        cell.textLabel?.attributedText = str

        cell.detailTextLabel?.text = product.name
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = self.filteredProducts[indexPath.row]

        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        self.addCode(codeEntry.code, codeEntry.template)
    }

    func addEnteredCode() {
        self.addCode(self.searchText, nil)
    }

    private func addCode(_ code: String, _ template: String?) {
        // popViewController has no completion handler, so we roll our own
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.delegate.track(.barcodeSelected(code))
            self.completion?(code, template)
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
