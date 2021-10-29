//
//  UITableView+ArrayDataSource.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit

class UITableViewViewArrayDataSource<T>: NSObject, UITableViewDataSource {
    typealias CellProvider = (_ tableView: UITableView, _ item: T, _ indexPath: IndexPath) -> UITableViewCell


    private(set) var items: [T]
    let cellProvider: CellProvider
    let tableView: UITableView

    init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.items = []
        self.cellProvider = cellProvider
        self.tableView = tableView
        super.init()
    }

    func item(at indexPath: IndexPath) -> T? {
        if items.count > indexPath.item && indexPath.section == 0 {
            return items[indexPath.item]
        } else {
            return nil
        }
    }

    func items(at indexPaths: [IndexPath]) -> [T] {
        indexPaths.compactMap { item(at: $0) }
    }

    func apply(_ items: [T]) {
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
            fatalError("unsupported indexPath")
        }
        return cellProvider(tableView, item, indexPath)
    }
}
