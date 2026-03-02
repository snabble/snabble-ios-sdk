//
//  AppAssetProvider.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import SnabbleAssetProviding

final class AppAssetProvider: AssetProviding {
    func primaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        nil
    }

    func secondaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        nil
    }

    func primaryButtonBackground(domain: Any?) -> (any View)? {
        nil
    }

    func primaryBorderedButtonBackground(domain: Any?) -> (any View)? {
        nil
    }

    func secondaryButtonBackground(domain: Any?) -> (any View)? {
        nil
    }

    func primaryButtonRadius(domain: Any?) -> CGFloat? {
        nil
    }

    func buttonFont(domain: Any?) -> Font? {
        nil
    }

    func buttonFontWeight(domain: Any?) -> Font.Weight? {
        nil
    }

    func shape(domain: Any?) -> (any Shape)? {
        nil
    }

    func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> Font? {
        nil
    }

    func color(named name: String, domain: Any?) -> UIColor? {
        UIColor(named: name)
    }

    func image(named name: String, domain: Any?) -> UIImage? {
        UIImage(named: name)
    }

    func image(named name: String, domain: Any?) -> SwiftUI.Image? {
        guard UIImage(named: name) != nil else {
            return nil
        }
        return SwiftUI.Image(name)
    }

    func localizedString(forKey key: String, arguments: CVarArg..., domain: Any?) -> String? {
        let format = Bundle.main.localizedString(forKey: key, value: key, table: nil)
        if format != key {
            return String.localizedStringWithFormat(format, arguments)
        }
        if key == "SnabbelDeveloperPassword" {
            return nil
        }
        return nil
    }

    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
    }
}
