//
//  UITableView+ArrayDataSource.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit

class UITableViewViewArrayDataSource<T, U: UITableViewCell>: NSObject, UITableViewDataSource where U: ReuseIdentifiable {
    typealias ConfigureBlock = (_ item: T, _ cell: U, _ index: Int) -> Void

    private(set) var items: [T]
    let configure: ConfigureBlock

    init(items: [T], configure: @escaping ConfigureBlock) {
        self.items = items
        self.configure = configure
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

    // MARK: TableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusable(U.self, for: indexPath)
        if let item = item(at: indexPath) {
            configure(item, cell, indexPath.item)
        }
        return cell
    }
}
