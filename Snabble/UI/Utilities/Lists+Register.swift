//
//  Lists+Register.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit

public protocol ReuseIdentifiable: class {
    static var reuseIdentifier: String { get }
}

public extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

public extension UITableView {
    func register<Cell>(_ type: Cell.Type) where Cell: ReuseIdentifiable, Cell: UITableViewCell {
        register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }

    func dequeueReusable<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell where Cell: ReuseIdentifiable, Cell: UITableViewCell {
        dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }

    func register<Header>(_ type: Header.Type) where Header: ReuseIdentifiable, Header: UITableViewHeaderFooterView {
        register(Header.self, forHeaderFooterViewReuseIdentifier: Header.reuseIdentifier)
    }

    func dequeueReusable<Header>(_ type: Header.Type) -> Header where Header: ReuseIdentifiable, Header: UITableViewHeaderFooterView {
        guard let header = dequeueReusableHeaderFooterView(withIdentifier: Header.reuseIdentifier) as? Header else {
            fatalError("register \(Header.self) to tableView: \(self)")
        }
        return header
    }
}

public extension UICollectionView {
    func register<Cell>(_ type: Cell.Type) where Cell: ReuseIdentifiable, Cell: UICollectionViewCell {
        register(Cell.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }

    func dequeueReusable<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell where Cell: ReuseIdentifiable, Cell: UICollectionViewCell {
        dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }

    func register<SupplementaryView>(_ type: SupplementaryView.Type, forSupplementaryViewOfKind kind: String) where SupplementaryView: ReuseIdentifiable, SupplementaryView: UICollectionReusableView {
        register(SupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: SupplementaryView.reuseIdentifier)
    }

    func dequeueReusable<SupplementaryView>(ofKind kind: String, withType type: SupplementaryView.Type, for indexPath: IndexPath) -> SupplementaryView where SupplementaryView: ReuseIdentifiable, SupplementaryView: UICollectionReusableView {
        dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SupplementaryView.reuseIdentifier, for: indexPath) as! SupplementaryView
    }
}
