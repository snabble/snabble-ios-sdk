//
//  AppDelegate+AssetProviding.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 22.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK
import SwiftUI
import UIKit

extension AppDelegate: AssetProviding {
    func color(named name: String, domain: Any?) -> UIColor? {
        nil
    }

    func color(named name: String, domain: Any?) -> SwiftUI.Color? {
        nil
    }

    func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight?, domain: Any?) -> UIFont? {
        UIFont.preferredFont(forTextStyle: style)
    }

    func image(named name: String, domain: Any?) -> UIImage? {
        UIImage(named: name)
    }

    func image(named name: String, domain: Any?) -> SwiftUI.Image? {
        nil
    }

    func localizedString(forKey: String, arguments: CVarArg..., domain: Any?) -> String? {
        nil
    }

    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL? {
        nil
    }
    func appearance(for domain: Any?) -> CustomAppearance? {
        nil
    }
}
