//
//  UI+Extentions.swift
//  SnabbleAssetProviding
//
//  Created by Uwe Tilemann on 11.06.24.
//

import SwiftUI

extension UIApplication {
    public var sceneKeyWindow: UIWindow? {
        windowScene?.windows
            .first(where: \.isKeyWindow)
    }
    
    public var windowScene: UIWindowScene? {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })
    }
}

public extension UITabBarController {
    var height: CGFloat {
        return self.tabBar.frame.size.height
    }
    
    var width: CGFloat {
        return self.tabBar.frame.size.width
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.sceneKeyWindow?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}
private extension UIEdgeInsets {
    var swiftUIInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension EnvironmentValues {
    public var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}
