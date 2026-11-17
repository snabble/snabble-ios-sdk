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
