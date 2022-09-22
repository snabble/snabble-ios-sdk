//
//  UIView+IndexPathInCollections.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.04.22.
//

import Foundation
import UIKit

public extension UIView {
    /// Searches indexPath of `self` in given `UITableView`
    /// - Parameter tableView: tableView which should cointain `self`
    /// - Returns: `IndexPath` of the associated `UITableView` or `nil` if not found
    func indexPath(in tableView: UITableView) -> IndexPath? {
        let position = convert(CGPoint.zero, to: tableView)
        return tableView.indexPathForRow(at: position)

    }

    /// Searches indexPath of `self` in given `UICollectionView`
    /// - Parameter collectionView: collectionView which should cointain `self`
    /// - Returns: `IndexPath` of the associated `UICollectionViewCell` or `nil` if not found
    func indexPath(in collectionView: UICollectionView) -> IndexPath? {
        let position = convert(CGPoint.zero, to: collectionView)
        return collectionView.indexPathForItem(at: position)
    }
}
