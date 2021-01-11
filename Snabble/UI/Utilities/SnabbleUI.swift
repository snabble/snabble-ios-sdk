//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// configuration parameters for the look of the view controllers in the Snabble SDK
public struct SnabbleAppearance: CustomAppearance {
    public var primaryColor: UIColor = .black
    public var backgroundColor: UIColor = .white

    // colors for buttons
    public var buttonShadowColor: UIColor = .black
    public var buttonBorderColor: UIColor = .black

    public var buttonBackgroundColor: UIColor {
        get {
            guard let customAppearance = customAppearance else {
                return _buttonBackgroundColor
            }
            return customAppearance.buttonBackgroundColor
        }
        set {
            _buttonBackgroundColor = newValue
        }
    }

    public var buttonTextColor: UIColor {
        get {
            guard let customAppearance = customAppearance else {
                return _buttonTextColor
            }
            return customAppearance.buttonTextColor
        }
        set {
            _buttonTextColor = newValue
        }
    }

    // bg color for the "stepper" buttons
    public var stepperButtonBackgroundColor: UIColor = .lightGray

    public var textColor: UIColor = .black

    public init() {}

    fileprivate var customAppearance: CustomAppearance?

    public var titleIcon: UIImage? {
        customAppearance?.titleIcon
    }

    private var _buttonBackgroundColor: UIColor = .lightGray
    private var _buttonTextColor: UIColor = .white
}

/// global settings for the Snabble UI classes
public enum SnabbleUI {

    /// set to false only if you want or need to take control of all navigation in the app (e.g. in the RN wrapper)
    public static var implicitNavigation = true

    public private(set) static var project = Project.none

    private(set) static var appearance = SnabbleAppearance()
    public static var customAppearance: CustomAppearance? {
        didSet {
            appearance.customAppearance = customAppearance
            customizableAppearances.objects.forEach {
                $0.setCustomAppearance(appearance)
            }
        }
    }

    /// sets the global appearance to be used. Your app must call `SnabbleUI.setup()` before instantiating any snabble view controllers
    public static func setup(_ appearance: SnabbleAppearance) {
        self.appearance = appearance
    }

    /// sets the project to be used
    public static func register(_ project: Project?) {
        self.project = project ?? Project.none

        if let project = project, project.id != Project.none.id, let manifestUrl = project.links.assetsManifest?.href {
            SnabbleUI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
        }
    }

    // MARK: - custom appearance handling

    private static var customizableAppearances: WeakCustomizableAppearanceSet = .init()

    static func registerForAppearanceChange(_ appearance: CustomizableAppearance) {
        customizableAppearances.reap()
        customizableAppearances.addObject(appearance)
    }

    static func unregisterForAppearanceChange(_ appearance: CustomizableAppearance) {
        customizableAppearances.reap()
        customizableAppearances.removeObject(appearance)
    }
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
