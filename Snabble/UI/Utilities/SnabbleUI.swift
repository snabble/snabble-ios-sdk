//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// global settings for the Snabble UI classes
public enum SnabbleUI {

    private(set) static var implicitNavigation = true

    /// set to false only if you want or need to take control of all navigation in the app (e.g. in the ReactiveNative wrapper)
    public static func setImplicitNavigation(_ isImplicitNavigation: Bool) {
        self.implicitNavigation = isImplicitNavigation
    }

    private(set) static var appearance: CustomAppearance = SnabbleAppearance() {
        didSet {
            UIColor.contrasts = appearance.contrastColors
            customizableAppearances.objects.forEach {
                $0.setCustomAppearance(appearance)
            }
        }
    }

    /// sets the global appearance to be used. Your app must call `SnabbleUI.setAppearance(_:)` before instantiating any snabble view controllers
    public static func setAppearance(_ appearance: CustomAppearance) {
        self.appearance = appearance
    }

    private(set) static var project: Project = .none

    /// sets the project to be used
    public static func register(_ project: Project?) {
        self.project = project ?? Project.none

        if let project = project, project.id != Project.none.id, let manifestUrl = project.links.assetsManifest?.href {
            SnabbleUI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
        }
    }

    // MARK: - custom appearance handling

    private static var customizableAppearances: WeakCustomizableAppearanceSet = .init()

    public static func registerForAppearanceChange(_ appearance: CustomizableAppearance) {
        customizableAppearances.reap()
        customizableAppearances.addObject(appearance)
    }
}

// Uses default implementations of the procotol
private struct SnabbleAppearance: CustomAppearance {
    var accentColor: UIColor { UIColor(rgbValue: 0x0077bb) }
    var titleIcon: UIImage? { nil }
    var contrastColors: [UIColor]? { nil }
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
