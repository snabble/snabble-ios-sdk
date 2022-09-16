//
//  WidgetVersionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import SwiftUI

public struct WidgetVersionView: View {
    
    var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "n/a"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "n/a"
        let appVersion = "v\(version) (\(build))"

        let commit = Bundle.main.infoDictionary?["SNGitCommit"] as? String ?? "n/a"
        let sdkVersion = SnabbleSDK.APIVersion.version

        let versionLine2 = BuildConfig.debug ? "SDK v\(sdkVersion)" : commit.prefix(6)
        return "Version \(appVersion) \(versionLine2)"
    }
    
    public var body: some View {
        Text(versionString)
    }
}
