//
//  Project+Trait.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-12.
//

import SnabbleComponents

extension SnabbleCore.Project {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
