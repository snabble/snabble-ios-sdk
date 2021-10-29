//
//  UITableView+ArrayDataSource.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit

class UITableViewViewArrayDataSource<ItemIdentifierType>: NSObject, UITableViewDataSource {
    typealias CellProvider = (_ tableView: UITableView, _ indexPath: IndexPath, _ itemIdentifier: ItemIdentifierType) -> UITableViewCell?


    private(set) var items: [ItemIdentifierType]
    let cellProvider: CellProvider
    let tableView: UITableView

    init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.items = []
        self.cellProvider = cellProvider
        self.tableView = tableView
        super.init()
    }

    func item(at indexPath: IndexPath) -> ItemIdentifierType? {
        if items.count > indexPath.item && indexPath.section == 0 {
            return items[indexPath.item]
        } else {
            return nil
        }
    }

    func items(at indexPaths: [IndexPath]) -> [ItemIdentifierType] {
        indexPaths.compactMap { item(at: $0) }
    }

    func apply(_ items: [ItemIdentifierType]) {
        self.items = items
        tableView.reloadData()
    }

    // MARK: TableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = item(at: indexPath) else {
            return UITableViewCell()
        }
        return cellProvider(tableView, indexPath, item) ?? UITableViewCell()
    }
}
