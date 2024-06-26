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
    private(set) static var appearance: CustomAppearance = SnabbleAppearance() {
        didSet {
            customizableAppearances.objects.forEach {
                $0.setCustomAppearance(appearance)
            }
        }
    }

    private(set) static var project: Project = .none

    /// sets the project to be used
    public static func register(_ project: Project?) {
        self.project = project ?? .none

        if let project = project, project.id != Project.none.id, let manifestUrl = project.links.assetsManifest?.href {
            SnabbleCI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
        }
        Asset.domain = project?.id
        Core.domain = project?.id
        self.appearance = Asset.provider?.appearance(for: project?.id) ?? SnabbleAppearance()
    }
    
    // MARK: - custom appearance handling

    private static var customizableAppearances: WeakCustomizableAppearanceSet = .init()

    public static func registerForAppearanceChange(_ customizable: CustomizableAppearance) {
        customizableAppearances.reap()
        customizableAppearances.addObject(customizable)

        customizable.setCustomAppearance(self.appearance)
    }
}

// Uses default implementations of the procotol
private struct SnabbleAppearance: CustomAppearance {
    var accent: UIColor { UIColor(red: 0, green: 119.0 / 255.0, blue: 187.0 / 255.0, alpha: 1) }
    var onAccent: UIColor { .white }
    var titleIcon: UIImage? { nil }
}

// since we can't have NSHashTable<CustomizableAppearance>, roll our own primitive weak wrapper
private class WeakCustomizableAppearance: Equatable, Hashable {
    private(set) weak var object: CustomizableAppearance?
    private let hashKey: Int

    init(_ object: CustomizableAppearance) {
        self.object = object
        self.hashKey = ObjectIdentifier(object).hashValue
    }

    static func == (lhs: WeakCustomizableAppearance, rhs: WeakCustomizableAppearance) -> Bool {
        if lhs.object == nil || rhs.object == nil { return false }
        return lhs.object === rhs.object
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashKey)
    }
}

private class WeakCustomizableAppearanceSet {
    private var _objects: Set<WeakCustomizableAppearance>

    init() {
        _objects = Set<WeakCustomizableAppearance>([])
    }

    init(_ objects: [CustomizableAppearance]) {
        _objects = Set<WeakCustomizableAppearance>(objects.map { WeakCustomizableAppearance($0) })
    }

    var objects: [CustomizableAppearance] {
        _objects.compactMap { $0.object }
    }

    func contains(_ object: CustomizableAppearance) -> Bool {
        _objects.contains(WeakCustomizableAppearance(object))
    }

    func addObject(_ object: CustomizableAppearance) {
        _objects.insert(WeakCustomizableAppearance(object))
    }

    func removeObject(_ object: CustomizableAppearance) {
        _objects.remove(WeakCustomizableAppearance(object))
    }

    func reap () {
        _objects = _objects.filter { $0.object != nil }
    }
}
