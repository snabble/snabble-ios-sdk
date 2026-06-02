//
//  Theme.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import SwiftUI
import UIKit

public enum Project: Equatable {
    case none
    case project(id: String)
}

public struct ProjectTrait: UITraitDefinition {
    /// Thread-safety: UITraitDefinition protocol requirement. Set once at type initialization, then only read.
    nonisolated(unsafe) public static var defaultValue: Project = .none
    nonisolated(unsafe) public static var affectsColorAppearance: Bool = true
    nonisolated(unsafe) public static var identifier: String = "io.snabble.components.project"
    nonisolated(unsafe) public static var name: String = "Project"
}


public struct ProjectEnvironmentKey: EnvironmentKey {
    /// Thread-safety: EnvironmentKey protocol requirement. Immutable constant.
    nonisolated(unsafe) public static var defaultValue = ProjectTrait.defaultValue
}

public extension EnvironmentValues {
    var projectTrait: Project {
        get { self[ProjectEnvironmentKey.self] }
        set { self[ProjectEnvironmentKey.self] = newValue }
    }
}

extension ProjectEnvironmentKey: UITraitBridgedEnvironmentKey {
    public static func read(from traitCollection: UITraitCollection) -> Project {
        traitCollection.project
    }
    
    public static func write(to mutableTraits: inout any UIMutableTraits, value: Project) {
        mutableTraits.project = value
    }
}

public extension UITraitCollection {
    var project: Project { self[ProjectTrait.self] }
}

public extension UIMutableTraits {
    var project: Project {
        get {
            self[ProjectTrait.self]
        }
        set {
            self[ProjectTrait.self] = newValue
        }
    }
}
