//
//  SelectionSheetTableView.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class SelectionSheetTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return contentSize
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }
}
