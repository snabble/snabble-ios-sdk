//
//  UIScrollView+Page.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 21.04.22.
//

import Foundation
import UIKit

extension UIScrollView {
    var currentPage: Int {
        Int(round(contentOffset.x / frame.width))
    }
}
