//
//  AppDelegate+AssetProviding.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 22.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleUI
import SwiftUI
import UIKit

extension AppDelegate: AssetProviding {
    func gatekeeper(viewModel: SnabbleUI.GatekeeperViewModel, domain: Any?) -> UIViewController? {
        return nil
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
            // default password is "Snabble" if return nil here
            return nil
        }
        return nil
    }

    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL? {
        let url = URL(string: "\(name ?? "")\(ext ?? "")")
        
        if let scheme = url?.scheme, scheme == "snabble", let resource = url?.absoluteString {
            let start = resource.index(resource.startIndex, offsetBy: scheme.count + "://".count)
            return Bundle.main.url(forResource: String(resource[start...]), withExtension: ext)
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    func appearance(for domain: Any?) -> CustomAppearance? {
        nil
    }
}
