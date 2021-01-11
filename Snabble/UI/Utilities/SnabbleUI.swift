//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// global settings for the Snabble UI classes
public enum SnabbleUI {

    /// set to false only if you want or need to take control of all navigation in the app (e.g. in the RN wrapper)
    public static var implicitNavigation = true

    public private(set) static var appearance: CustomAppearance = SnabbleAppearance() {
        didSet {
            customizableAppearances.objects.forEach {
                $0.setCustomAppearance(appearance)
            }
        }
    }

    /// sets the global appearance to be used. Your app must call `SnabbleUI.setAppearance(_:)` before instantiating any snabble view controllers
    public static func setAppearance(_ appearance: CustomAppearance) {
        self.appearance = appearance
    }

    public private(set) static var project = Project.none

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

private struct SnabbleAppearance: CustomAppearance {
    var primaryColor: UIColor = .black
    var backgroundColor: UIColor = .white

    // colors for buttons
    var buttonShadowColor: UIColor = .black
    var buttonBorderColor: UIColor = .black
    var buttonBackgroundColor: UIColor = .lightGray
    var buttonTextColor: UIColor = .white

    // bg color for the "stepper" buttons
    var stepperButtonBackgroundColor: UIColor = .lightGray

    var textColor: UIColor = .black

    var titleIcon: UIImage?
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
