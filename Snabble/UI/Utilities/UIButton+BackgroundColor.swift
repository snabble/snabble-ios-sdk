//
//  UIButton+BackgroundColor.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit

extension UIButton {
    func setBackgroundColor(color: UIColor?, for state: UIControl.State) {
        setBackgroundImage(colorImage(color), for: state)
    }

    private func colorImage(_ color: UIColor?) -> UIImage? {
        guard let color = color else {
            return nil
        }

        let onePixel = 1 / UIScreen.main.scale
        let rect = CGRect(x: 0, y: 0, width: onePixel, height: onePixel)
        UIGraphicsBeginImageContextWithOptions(rect.size, color.cgColor.alpha == 1, 0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
