//
//  MultilineButton.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

// a UIButton that correctly scales its height when the titleLabel doesn't fit in 1 line
// e.g. with large dynamic font sizes

final class MultilineButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.numberOfLines = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let size = titleLabel?.intrinsicContentSize, let insets = configuration?.contentInsets else {
            return super.intrinsicContentSize
        }
        
        return CGSize(width: size.width + insets.leading + insets.trailing,
                      height: size.height + insets.top + insets.bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let width = titleLabel?.frame.size.width {
            titleLabel?.preferredMaxLayoutWidth = width
        }
    }
}
