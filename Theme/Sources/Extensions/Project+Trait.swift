//
//  Project+Trait.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-12.
//  Moved from Core to Components on 2026-03-27 to resolve circular dependency
//  Moved from Components to Theme on 2026-03-28 (better semantic fit)
//

import SnabbleCore

extension SnabbleCore.Project {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
