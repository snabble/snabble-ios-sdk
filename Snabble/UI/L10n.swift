//
//  L10n.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

extension Snabble {
    public static func l10n(_ key: String, _ table: String = "") -> String {
        // check if the app has a project-specific localization for this string
        let projectId = SnabbleUI.project.id.rawValue.replacingOccurrences(of: "-", with: ".")
        let projectKey = "\(projectId).\(key)"
        let projectValue = Bundle.main.localizedString(forKey: projectKey, value: projectKey, table: nil)
        if !projectValue.hasPrefix(projectId) {
            return projectValue
        }

        // check if the app has localized this string
        let upper = key.uppercased()
        let appValue = Bundle.main.localizedString(forKey: key, value: upper, table: nil)
        if appValue != upper {
            return appValue
        }

        // check the SDK's localization file
        let sdkValue = SnabbleSDKBundle.main.localizedString(forKey: key, value: upper, table: "SnabbleLocalizable")
        return sdkValue
    }
}
