//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

/// global settings for the Snabble UI classes
public enum SnabbleCI {
    nonisolated(unsafe) public private(set) static var project: Project = .none

    /// sets the project to be used
    public static func register(_ project: Project?) {
        self.project = project ?? .none

        if let project = project, project.id != Project.none.id, let manifestUrl = project.links.assetsManifest?.href {
            SnabbleCI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
        }
        Asset.domain = project?.id
        Core.domain = project?.id
    }
}
