//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// configuration parameters for the look of the view controllers in the Snabble SDK
public struct SnabbleAppearance {
    public var primaryColor = UIColor.black
    public var backgroundColor = UIColor.white

    // colors for buttons
    public var buttonShadowColor = UIColor.black
    public var buttonBorderColor = UIColor.black
    public var buttonBackgroundColor = UIColor.lightGray
    public var buttonTextColor = UIColor.white

    // bg color for the "stepper" buttons
    public var stepperButtonBackgroundColor = UIColor.lightGray

    public var textColor = UIColor.black

    public init() {}
}

/// global settings for the Snabble UI classes
public enum SnabbleUI {

    /// set to false only if you want or need to take control of all navigation in the app (e.g. in the RN wrapper)
    public static var implicitNavigation = true
    public private(set) static var appearance = SnabbleAppearance()
    public private(set) static var project = Project.none

    /// sets the global appearance to be used. Your app must call `SnabbleUI.setup()` before instantiating any snabble view controllers
    public static func setup(_ appearance: SnabbleAppearance) {
        self.appearance = appearance
    }

    /// update the global appearance
    public static func customizeAppearance(_ custom: CustomAppearance) {
        self.appearance.buttonBackgroundColor = custom.buttonBackgroundColor
        self.appearance.buttonTextColor = custom.buttonTextColor
    }

    /// sets the project to be used
    public static func register(_ project: Project?) {
        self.project = project ?? Project.none

        if let project = project, project.id != Project.none.id, let manifestUrl = project.links.assetsManifest?.href {
            SnabbleUI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
        }
    }

    // MARK: - custom appearance handling

    private static var appearanceVCs = [CustomizableAppearanceWrapper]()

    public static func registerForAppearanceChange(_ viewController: CustomizableAppearance) {
        self.appearanceVCs = self.appearanceVCs.filter { $0.ca != nil }
        let wrapper = CustomizableAppearanceWrapper(viewController)
        self.appearanceVCs.append(wrapper)
    }

    public static func setCustomAppearance(_ appearance: CustomAppearance) {
        SnabbleUI.customizeAppearance(appearance)
        self.appearanceVCs.forEach {
            $0.ca?.setCustomAppearance(appearance)
        }
    }
}

// since we can't have NSHashTable<CustomizableAppearance>, roll our own primitive weak wrapper
private class CustomizableAppearanceWrapper {
    private(set) weak var ca: CustomizableAppearance?

    init(_ ca: CustomizableAppearance) {
        self.ca = ca
    }
}
